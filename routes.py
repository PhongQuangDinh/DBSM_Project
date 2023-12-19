from flask import Flask, render_template, redirect, request
from db import *
app = Flask(__name__)

@app.route('/', methods = ['POST','GET'])
def login():
    print('get started')
    return "<h1>FUCKING HELLO WORLD</h1>"