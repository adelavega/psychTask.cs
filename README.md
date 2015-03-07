psychTask.cs
==================

Template task using CoffeeScript that can be expanded to specific tasks. Set up to run with psiTurk on OpenShift

To get this up and running:

1. Obviously, customize static/coffee/task.coffee to be your actual task and use coffee script to compile to js:

    coffee -cw -o static/js/ static/coffee/

2. Change text in all templates to match your task

3. On OpenShift, add a MySQL cartridge and replace config.txt with config_os.txt

4. Edit config file with your credentials, and MySQL url

5. Once you run your task on OpenShift, you can access your data by running download_data.py on the server. You can run this remotely from an IPython notebook to get latest data (outputs to STDOUT)
