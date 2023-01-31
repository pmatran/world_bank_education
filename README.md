

[![GitHub](https://badgen.net/badge/icon/github?icon=github&label)](https://github.com)
[![made-with-python](https://img.shields.io/badge/Made%20with-Python-1f425f.svg)](https://www.python.org/)
[![Open Source? Yes!](https://badgen.net/badge/Open%20Source%20%3F/Yes%21/blue?icon=github)](https://github.com/Naereen/badges/)
[![Awesome Badges](https://img.shields.io/badge/badges-awesome-green.svg)](https://github.com/Naereen/badges)


<br>
<H1 align="center">
	<img height="50" width="250" src="https://upload.wikimedia.org/wikipedia/commons/8/87/The_World_Bank_logo.svg">
	<br>
	<br>
	<b>Education Statistics Dataset</b>
</H1>
<br>
<br>


Description & Content
-----------------------------------------------
This project is a simple Data Science analysis in SQL language based on World Bank EdStats dataset ...


Installation
------------------------------------------------
To have a look and manipulate the main datasets, please consider the following steps:

1. **First, clone this project:**

_Via https_
```shell
git clone https://github.com/pmatran/world_bank_education.git
```
_Via ssh_
```shell
git clone git@github.com:pmatran/world_bank_education.git
```

2. **Next, make sure to install all required dependencies:**

```shell
pip install -r requirements.txt
```

3. Finally download and send data to your local MS SQL Server from terminal

_General usage_
```shell
python send2sqlserver.py -s [--server] <SQLServer-name> -db [--database] <Database-name>
```

_Example_
```shell
python send2sqlserver.py -s 'MSI\SQLEXPRESS' -db Education
```


Ressources
-----------------------------------------------
+ [Education Statistics Dataset](https://datacatalog.worldbank.org/search/dataset/0038480)


Disclaimer :no_entry:
-----------------------------------------------
This project was created to evaluate the SQL skills of all collaborators ([@pmatran](https://github.com/pmatran), ... add yours) by their professor at M2-IASchool (Bordeaux, FRANCE).