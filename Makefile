PYTHON_VIRTUALENV 		:= lambda-backup-worker/venv
PYTHON_SRC				:= lambda-backup-worker/src
PYTHON_REQUIREMENTS 	:= lambda-backup-worker/src/requirements.txt

all: libraries

.PHONY: clean
clean: 
	rm -rf $(PYTHON_SRC)/pytz
	rm -rf $(PYTHON_VIRTUALENV)

.PHONY: dist
dist: libraries
	rm -rf $(PYTHON_VIRTUALENV)

.PHONY: iam
iam:
	terraform apply -target=module.iam

.PHONY: lambda-backup-worker
lambda-backup-worker:
	terraform apply -target=module.lambda-backup-worker

.PHONY: lambda-backup-schedule
lambda-backup-schedule:
	terraform apply -target=module.lambda-backup-schedule

$(PYTHON_VIRTUALENV):
	virtualenv $(PYTHON_VIRTUALENV)
	$(PYTHON_VIRTUALENV)/bin/pip install -r $(PYTHON_REQUIREMENTS)

.PHONY: libraries
libraries: $(PYTHON_VIRTUALENV) $(PYTHON_SRC)/pytz

$(PYTHON_SRC)/pytz: $(PYTHON_VIRTUALENV)
	cp -r $(PYTHON_VIRTUALENV)/lib/python2.7/site-packages/pytz $(PYTHON_SRC)