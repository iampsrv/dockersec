from flask import Blueprint, jsonify

main = Blueprint('main', __name__)

@main.route('/')
def index():
    return "Hello, DevSecOps Flask!"

@main.route('/health')
def health():
    return jsonify(status="ok"), 200
