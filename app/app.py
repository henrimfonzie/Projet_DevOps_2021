from create_app import app
import routes
import logging
from datetime import date

today = date.today()
if __name__ == '__main__':
    logfile=str(today)+".log"
    logging.basicConfig(filename=logfile,level=logging.DEBUG)
    app.run(host="0.0.0.0", debug=True)