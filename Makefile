##variables
USER=appuser
DIR=/opt/app
SVR_FILE=server.py
ENV_FILE=.env
LOG_FILE=app.logrotate
LOG_PATH=/var/log/app.log
SVC_FILE=app.service
HC_SH_FILE=healthcheck.sh
HEALTHCHECK_SCRIPT_PATH=/usr/local/bin/healthcheck.sh
CRONJOB_PATH=/etc/cron.d/healthcheck

##phony allows the use of a single makefile (all targets should be executed when called and are not seperate files)
.PHONY: all install user directory server start_service check_service logrotate fierwall healthcheck cron clean

##running all will install the service, fierwall, healthcheck and healthcheck cronjob
all: install firewall healthcheck cron

##running insall on it's own will complete all essential steps for the service to be running
install: user directory server systemd start_service check_service logrotate

##user target, this creates the user if it doesn't exisit. If it does exist nothing is done
user:
	@echo "creating user $(USER)..."
	@if ! id -u $(USER) >/dev/null 2>&1; then \
		sudo useradd -r -s /bin/false $(USER); \
		echo "✔ User $(USER) created."; \
	else \
		echo "User $(USER) already exists."; \
	fi

##directory target, this creates a working directory and gives full access to the prevously created user
directory:
	@echo "creating directory $(DIR)..."
	sudo mkdir -p $(DIR)
	@echo "directory $(DIR) created"
	@echo "granting access to user $(USER)..."
	sudo chown $(USER):$(USER) $(DIR)
	sudo chmod 750 $(DIR)
	@echo "✔ access granted"

##server target, this adds the server and env files to the VM and gives ownership to the previously created user
server:
	@echo "installing server files..."
	sudo cp $(SVR_FILE) $(DIR)/
	sudo cp $(ENV_FILE) $(DIR)/
	sudo chown $(USER):$(USER) $(DIR)/$(SVR_FILE) $(DIR)/$(ENV_FILE)
	@echo "✔ server files sucessfully installed"

##systemd target, this creates the .service file
systemd:
	@echo "Creating systemd service..."
	sudo cp $(SVC_FILE) /etc/systemd/system/app.service
	@echo "✔ systemd service created"

##start service target, this starts the app service which was just created
start_service:
	@echo "Reloading systemd and starting service..."
	sudo systemctl daemon-reload
	sudo systemctl enable app
	sudo touch $(LOG_PATH)
	sudo chown $(USER):$(USER) $(LOG_PATH)
	sudo systemctl start app
	@echo "✔ app started"


##check service target, this verifies the service is responding on the correct port and checks the systemd service is running
check_service:
	@echo "Checking service status..."
	curl --fail http://localhost:8080 && echo "✔ Service responded with 200 OK"
	sudo systemctl status app --no-pager && echo "✔ Service is running"

##logrotate target, this creates configures logrotae defineing how long logs should be stored
logrotate:
	@echo "Creating logrotate config..."
	sudo cp $(LOG_ROTATE_FILE) /etc/logrotate.d/app
	@echo "✔ logrotate config created"

#fierwall target, this checks if ufw is installed if it is a rule will be created ensuring only localhost acess on port 8080
firewall:
	@echo "Configuring UFW to allow only localhost on port 8080..."
	@if ! command -v ufw >/dev/null 2>&1; then \
		echo "ufw is not installed. Please install ufw and rerun."; exit 1; \
	fi
	sudo ufw allow from 127.0.0.1 to any port 8080
	sudo ufw deny 8080
	sudo ufw reload || true
	sudo ufw status verbose
	@echo "✔ firewall configured"

#healthcheck target, this creates a script firewall:
	@echo "Configuring UFW to allow only localhost on port 8080..."
	@if ! command -v ufw >/dev/null 2>&1; then \
		echo "ufw is not installed. Please install ufw and rerun."; exit 1; \
	fi
	sudo ufw allow from 127.0.0.1 to any port 8080
	sudo ufw deny 8080
	sudo ufw reload || true
	sudo ufw status verbose
	@echo "✔ firewall configured"to check if the service is running
healthcheck:
	@echo "Creating healthcheck script..."
	sudo cp $(HC_SH_FILE) $(HEALTHCHECK_SCRIPT_PATH)
	@echo "✔ healthcheck script created"

#cron target, this creates a cron job to run the healthcheck script every 5 minuets
cron:
	@echo "Setting up cronjob for healthcheck every 5 minutes..."
	echo "*/5 * * * * root $(HEALTHCHECK_SCRIPT_PATH)" | sudo tee $(CRONJOB_PATH)
	sudo chmod 644 $(CRONJOB_PATH)
	@echo "✔ cronjob created"

#clean target, this removes everything created using the other commands
clean:
	sudo systemctl stop app || true
	sudo systemctl disable app || true
	sudo rm -f /etc/systemd/system/app.service
	sudo rm -rf $(DIR)
	sudo rm -f $(LOG_PATH)
	sudo rm -f /etc/logrotate.d/app
	sudo rm -f $(HEALTHCHECK_SCRIPT_PATH)
	sudo rm -f $(CRONJOB_PATH)
	sudo ufw delete allow from 127.0.0.1 to any port 8080 || true
	sudo ufw delete deny 8080 || true
	sudo userdel -r $(USER) || true
	@echo "✔ cleanup scuessfull"