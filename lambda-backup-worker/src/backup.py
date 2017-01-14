import boto3
import pytz

from datetime import datetime, timedelta

ec = boto3.client('ec2')


def ec2_resource_tags(resource_id):
    tags = ec.describe_tags(
        Filters=[
            {
                'Name': 'resource-id',
                'Values': [resource_id]
            },
        ],
    ).get(
        'Tags', []
    )
    return tags_dict(tags)


def tags_dict(tags):
    d = {}
    for tag in tags:
        d[tag['Key']] = tag['Value']
    return d


def lambda_handler(event, context):
    reservations = ec.describe_instances(
        Filters=[
            {'Name': 'tag-key', 'Values': ['backup', 'Backup']},
        ]
    ).get(
        'Reservations', []
    )

    instances = sum(
        [
            [i for i in r['Instances']]
            for r in reservations
        ], [])

    print "Found %d instances that need backing up" % len(instances)

    for instance in instances:

        for dev in instance['BlockDeviceMappings']:

            if dev.get('Ebs', None) is None:
                continue

            vol_id = dev['Ebs']['VolumeId']
            print "Found EBS volume %s on instance %s" % (
                vol_id, instance['InstanceId'])

            # Existing Instance and EBS volume tags
            instance_tags = tags_dict(instance['Tags'])
            ebs_tags = ec2_resource_tags(vol_id)

            update_ebs_tags = []
            cost_tag_names = ['CostCode', 'Location', 'Client', 'Project', 'Environment', 'Owner']
            cost_tags = {}

            # Find cost allocation metadata from volumes or instances
            for tag_name in cost_tag_names:

                if tag_name in ebs_tags:
                    print "Volume %s %s is %s" % (vol_id, tag_name, ebs_tags[tag_name])
                    cost_tags[tag_name] = ebs_tags[tag_name]

                elif tag_name in instance_tags:
                    print "%s tag not found for volume %s - instance %s is %s" % (
                        tag_name,
                        vol_id,
                        tag_name,
                        instance_tags[tag_name]
                    )
                    # Add missing tags to the EBS volume
                    update_ebs_tags.append({
                        'Key': tag_name,
                        'Value': instance_tags[tag_name]
                    })
                    cost_tags[tag_name] = instance_tags[tag_name]

                else:
                    print "Volume or instance tag %s not found" % tag_name
            
            # Check if snapshot was created recently
            # TODO: Query snapshots from AWS
            schedule_snapshot = True
            t = datetime.now(pytz.utc)
            if 'BackupSnapshot' in ebs_tags:
                scheduled = datetime.strptime(ebs_tags['BackupSnapshot'], "%Y-%m-%dT%H:%M:%S.%f+00:00").replace(tzinfo=pytz.utc)
                if scheduled > t - timedelta(minutes=5):
                    print "Previous scheduled time %s is less than 5 minutes ago" % str(scheduled)
                    schedule_snapshot = False

            # Add BackupSnapshot if new backup snapshot will be created
            if schedule_snapshot:
                update_ebs_tags.append({
                    'Key': 'BackupSnapshot',
                    'Value': t.isoformat() 
                })

            # Update EBS volume tags if required
            if len(update_ebs_tags) > 0:
                print "Updating tags in the EBS volume %s..." % vol_id
                ec.create_tags(
                    Resources=[
                        vol_id,
                    ],
                    Tags=update_ebs_tags
                )   

            # Create snapshot if required
            if schedule_snapshot:

                print "Creating snapshot from EBS volume %s..." % vol_id
                snapshot_description = 'Created by %s (RequestId: %s, Version: %s, Instance: %s, Volume: %s)' % (
                    context.function_name, 
                    context.aws_request_id,
                    context.function_version,
                    instance['InstanceId'],
                    vol_id,
                )
                snapshot = ec.create_snapshot(
                    VolumeId=vol_id,
                    Description=snapshot_description
                )

                # Create tags for the snapshot
                snapshot_tags = []
                for key, value in cost_tags.iteritems():
                    snapshot_tags.append({
                        'Key': key,
                        'Value': value
                    })

                # Update tags
                if len(snapshot_tags) > 0:
                    print "Updating tags for snapshot %s..." % snapshot['SnapshotId']
                    ec.create_tags(
                        Resources=[
                            snapshot['SnapshotId'],
                        ],
                        Tags=snapshot_tags
                    )   