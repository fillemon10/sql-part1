CREATE TABLE Students(
    idnr CHAR(10) PRIMARY KEY,
    name TEXT NOT NULL,
    login TEXT NOT NULL,
    program TEXT NOT NULL
);

CREATE TABLE Branches(
    name TEXT,
    program TEXT,
    PRIMARY KEY (name, program)
);

CREATE TABLE Courses(
    code CHAR(6) PRIMARY KEY,
    name TEXT NOT NULL,
    credits FLOAT NOT NULL,
    department TEXT NOT NULL
);

CREATE TABLE LimitedCourses(
    code CHAR(6) PRIMARY KEY,
    capacity INT NOT NULL CHECK (capacity >= 0), 
    FOREIGN KEY (code) REFERENCES Courses(code)
);

CREATE TABLE StudentBranches(
    student CHAR(10) PRIMARY KEY,
    branch TEXT NOT NULL,
    program TEXT NOT NULL,
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
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
    FOREIGN KEY (course) REFERENCES Courses(code)
);

CREATE TABLE MandatoryBranch(
    course CHAR(6),
    branch TEXT,
    program TEXT,
    PRIMARY KEY(course, branch, program),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);

CREATE TABLE RecommendedBranch(
    course CHAR(6),
    branch TEXT,
    program TEXT,
    PRIMARY KEY(course, branch, program),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
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
