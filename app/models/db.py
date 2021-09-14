
import configparser
# url de connection a la bdd se basant sur data.cfg
# fichier a modier selon l'environnement

config = configparser.ConfigParser()
config.read('/app/data.cfg')
env=config['ENV']['name']
RDS_URL = "mysql+pymysql://" + config[env]['user'] + ":" + config[env]['pwd'] + "@" + config[env]['host'] + "/" + config[env]['bd']
