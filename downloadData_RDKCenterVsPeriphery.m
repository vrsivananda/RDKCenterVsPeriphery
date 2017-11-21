clear;
close all;

%First, add the java file that you'll need to connect
%(This needs to be in the same directory or have the path added)
%Get this file from the Oracle website if you don't have it otherwise.
javaaddpath('mysql-connector-java-5.1.42-bin.jar');


%Next, create a connection object by connecting to our SQL database.
databaseName = '';
databasePassword = '';
serverAddess = '';
conn = database('psych_qualia',databaseName,databasePassword,'Vendor','MySQL',...
    'Server',serverAddess);


%Then, load a text file that lists all of the subjects.
path='Expt2_Subjects.txt';
subjectListFid=fopen(path);
tot = fscanf(subjectListFid,'%d');