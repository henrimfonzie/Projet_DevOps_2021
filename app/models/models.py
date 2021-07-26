from sqlalchemy import create_engine
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import sessionmaker

Base = automap_base()
engine = create_engine('mysql+pymysql://admin:Password123@rdstest2.cz3sp07bq1rp.eu-west-3.rds.amazonaws.com/projet_devops_2021', echo=False)

Base.prepare(engine, reflect=True)

Session = sessionmaker(bind=engine)
session = Session()


Avoir = Base.classes.avoir

Qcm = Base.classes.qcm

Questions = Base.classes.questions

Utilisateur = Base.classes.utilisateur

Historique = Base.classes.historique
