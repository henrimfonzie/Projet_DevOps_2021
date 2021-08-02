from flask import render_template, redirect, url_for, request, Flask, session

app = Flask(__name__)
app.secret_key = "test"