
import configparser

config = configparser.ConfigParser()
config.read('data.cfg')
RDS_URL = "mysql+pymysql://" + config['RDS']['user'] + ":" + config['RDS']['pwd'] + "@" + config['RDS']['host'] + "/" + config['RDS']['bd']
