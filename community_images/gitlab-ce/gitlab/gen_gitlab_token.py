#!/usr/bin/python3
"""
Script that creates Personal Access Token for Gitlab API;
Tested with:
- Gitlab Community Edition 10.1.4
- Gitlab Enterprise Edition 12.6.2
- Gitlab Enterprise Edition 13.4.4
"""
import sys
import requests
from urllib.parse import urljoin
from bs4 import BeautifulSoup
import json

endpoint = "https://localhost:6643"
root_route = urljoin(endpoint, "/")
sign_in_route = urljoin(endpoint, "/users/sign_in")
pat_route = urljoin(endpoint, "/-/profile/personal_access_tokens")

login = "root"
password = "adminadmin"


def find_csrf_token(text):
    soup = BeautifulSoup(text, "lxml")
    token = soup.find(attrs={"name": "csrf-token"})
    param = soup.find(attrs={"name": "csrf-param"})
    data = {param.get("content"): token.get("content")}
    return data


def obtain_csrf_token():
    r = requests.get(root_route, verify=False)
    token = find_csrf_token(r.text)
    return token, r.cookies


def obtain_authenticity_token(cookies):
    r = requests.get(pat_route, cookies=cookies, verify=False)
    soup = BeautifulSoup(r.text, "lxml")
    token = soup.find(attrs={'name': 'csrf-token'})
    param = soup.find(attrs={'name': 'csrf-param'})
    return token.get("content")
    #return token


def sign_in(csrf, cookies):
    data = {
        "user[login]": login,
        "user[password]": password,
        "user[remember_me]": 0,
        "utf8": "✓"
    }
    data.update(csrf)
    r = requests.post(sign_in_route, data=data, cookies=cookies, verify=False)
    token = find_csrf_token(r.text)
    return token, r.history[0].cookies


def obtain_personal_access_token(name, expires_at, csrf, cookies, authenticity_token):
    data = {
        "personal_access_token[expires_at]": expires_at,
        "personal_access_token[name]": name,
        "personal_access_token[scopes][]": "api",
        "authenticity_token": authenticity_token,
        "utf8": "✓"
    }
    data.update(csrf)
    r = requests.post(pat_route, data=data, cookies=cookies, verify=False)
    soup = BeautifulSoup(r.text, "lxml")
    #token = soup.find('input', id='created-personal-access-token').get('value')
    json_string = json.loads(r.text)
    token = json_string["new_token"]
    return token


def main():
    csrf1, cookies1 = obtain_csrf_token()
    csrf2, cookies2 = sign_in(csrf1, cookies1)
    authenticity_token = obtain_authenticity_token(cookies2)

    name = sys.argv[1]
    expires_at = sys.argv[2]
    token = obtain_personal_access_token(name, expires_at, csrf2, cookies2, authenticity_token)
    print(token)


if __name__ == "__main__":
    main()
