from sqlalchemy import create_engine
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import sessionmaker
import configparser

config = configparser.ConfigParser()
config.read('data.cfg')
RDS_URL = "mysql+pymysql://" + config['RDS']['user'] + ":" + config['RDS']['pwd'] + "@" + config['RDS']['host'] + "/" + config['RDS']['bd']

Base = automap_base()
engine = create_engine(RDS_URL, echo=False)

Base.prepare(engine, reflect=True)

Session = sessionmaker(bind=engine)
session = Session()


Avoir = Base.classes.avoir

Qcm = Base.classes.qcm

Questions = Base.classes.questions

Utilisateur = Base.classes.utilisateur

Historique = Base.classes.historique
