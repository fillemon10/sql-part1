CREATE TABLE Departments(
    name TEXT PRIMARY KEY,
    abrv TEXT NOT NULL UNIQUE
);

CREATE TABLE Programs(
    name TEXT PRIMARY KEY,
    abrv TEXT NOT NULL
);

CREATE TABLE Branches(name TEXT PRIMARY KEY);

CREATE TABLE Students(
    idnr CHAR(10) PRIMARY KEY,
    name TEXT NOT NULL,
    login TEXT NOT NULL UNIQUE,
    program TEXT NOT NULL,
    FOREIGN KEY (program) REFERENCES Programs(name)
);

CREATE TABLE Courses(
    code CHAR(6) PRIMARY KEY,
    name TEXT NOT NULL,
    credits FLOAT NOT NULL CHECK (credits >= 0),
    department TEXT NOT NULL,
    FOREIGN KEY (department) REFERENCES Departments(name)
);

CREATE TABLE LimitedCourses(
    code CHAR(6) PRIMARY KEY,
    capacity INT NOT NULL CHECK (capacity >= 0),
    FOREIGN KEY (code) REFERENCES Courses(code)
);

CREATE TABLE StudentBranches(
    student CHAR(10) PRIMARY KEY,
    branch TEXT NOT NULL,
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (branch) REFERENCES Branches(name)
);

CREATE TABLE Classifications(name TEXT PRIMARY KEY);

CREATE TABLE Classified(
    course CHAR(6),
    classification TEXT,
    PRIMARY KEY (course, classification),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (classification) REFERENCES Classifications(name)
);

CREATE TABLE MandatoryProgram(
    course CHAR(6),
    program TEXT,
    PRIMARY KEY (course, program),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (program) REFERENCES Programs(name)
);

CREATE TABLE MandatoryBranch(
    course CHAR(6),
    branch TEXT,
    PRIMARY KEY(course, branch),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (branch) REFERENCES Branches(name)
);

CREATE TABLE RecommendedBranch(
    course CHAR(6),
    branch TEXT,
    PRIMARY KEY(course, branch),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (branch) REFERENCES Branches(name)
);

CREATE TABLE Registered(
    student CHAR(10),
    course CHAR(6),
    PRIMARY KEY(course, student),
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES Courses(code)
);

CREATE TABLE Taken(
    student CHAR(10),
    course CHAR(6),
    grade CHAR(1) DEFAULT 0 NOT NULL,
    CONSTRAINT okgrade CHECK (grade IN ('U', '3', '4', '5')),
    PRIMARY KEY(course, student),
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES Courses(code)
);

CREATE TABLE WaitingList(
    student CHAR(10),
    course CHAR(6),
    position TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(course, student),
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES LimitedCourses(code)
);

CREATE TABLE PreRequisites(
    course CHAR(6),
    prerequisiteCourse CHAR(6),
    PRIMARY KEY(course, prerequisiteCourse),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (prerequisiteCourse) REFERENCES Courses(code)
);

CREATE TABLE PartOfDepartment(
    program TEXT NOT NULL,
    department TEXT NOT NULL,
    PRIMARY KEY(program, department),
    FOREIGN KEY (program) REFERENCES Programs(name),
    FOREIGN KEY (department) REFERENCES Departments(name)
);

CREATE TABLE PartOfProgram(
    branch TEXT NOT NULL,
    program TEXT NOT NULL,
    PRIMARY KEY(branch, program),
    FOREIGN KEY (branch) REFERENCES Branches(name),
    FOREIGN KEY (program) REFERENCES Programs(name)
);

CREATE TABLE GivenByDepartment(
    course CHAR(6) NOT NULL,
    department TEXT NOT NULL,
    PRIMARY KEY(course, department),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (department) REFERENCES Departments(name)
);
