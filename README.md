# MEL-EEL-Database

This document serves as an explanation to all the files used in order to create various documents related to the EC&I department (Electrical Load List, Cable List, etc.). 

## Steps for Database Workflow

The following section presents the steps required for the document creation through the SQL Database.

### Step 1: Database Creation

This Step serves to create a database, in which all data and tables will be created.

**here will be a need to define a Database creation which will use the project Tag as a variable (which will help create a database per project).**

### Step 2: Schemas Creation

This Step serves to create the Schemas used to separate various processes in the calculations (such as reference, staging, core, audit, out).

### Step 3: Reference tables

This Step serves to define the various base references for calculations and variable definition. Here are the various reference tables implemented to date:

- Column aliases (conversion of column headers, which allows the creation of a link between two column despite having two different headers.)

- Unit dictionary (conversion of units, which allows consistency within created documents despite source values differing.)

- Demand Factors (defines constant demand factors for various equipment types.)

**Reference tables will be added as needed throughout the development of the project.**

### Step 4: Core, Staging and Auditing Schemas

This Step serves to process the data received in order to create a clean database with a revision history, in order to keep track of changes made throughout the project. The relevant Schemas are:

- Staging Schema: Serves as a transition step for the database, where the data received is stored, before being cleaned and validated.

- Core Schema: Serves as the master data, where the clean data is stored. This is the table that should be accessed in order to read the data.

- Auditing Schema: Serves as a revision tracker, where change logs are accessible.

### Step 5: Viewing

This Step serves to create an editable view (table) of the database.

### Step 6 Calculations

This Step serves to

### Step 7 Security

This Step serves to

## Front-end/User Interface

The following section defines the various methods through which any given user will be able to apply changes to the database.

### Excel document

The user interface will be an Excel document, which will serve as a source for the Mechanical Equipment List (MEL) and the Electrical Equipment List (EEL).

The buttons will be useable within the Excel document, as detailed below:

#### Update MEL

The following button is used to push the values written within the MEL into the Database.

**This button must be programmed using VBA macros.**

#### Generate Load List

the following button is used to generate the load list based on the tables created in the database.

**This button could be changed to create the load list into a new document instead of a worksheet within the MEL.**

## Work to be done

The following list presents various tasks left to do in order to complete this project. Please note that this list will be updated as needed.

- Define a repository accessible throughout the company.

- Define security and access constraints.

- Create VBA Macro for Excel MEL to push data onto the Server.

- Define automatic workflow in database to proceed throughout the various steps.

- Define Project variable in order to define project-specific databases.

- Define calculation steps for typical load list.

- Define data validation and error correction.

- Define method for manual modification of created load list (push manual changes from excel to the load list).

- 
