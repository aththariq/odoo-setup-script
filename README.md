# Odoo Installation Script

Run the following Commands in Terminal:

```bash
curl -LO https://raw.githubusercontent.com/aththariq/odoo-setup-script/refs/heads/main/setup_odoo.sh && chmod +x setup_odoo.sh && ./setup_odoo.sh
```

Congratulations 🎉 for completing the setup!  
You Have Successfully Installed and Configured Odoo on Your System.  

Well done!  

### Additional Notes:
- The script will prompt you to enter PostgreSQL username and password. Please provide the required details when prompted.
- After the script finishes, you can run Odoo using the following command:
  ```bash
  source $HOME/odoo/odoo-venv/bin/activate && ./odoo-bin -c $HOME/odoo/odoo.conf
  ```