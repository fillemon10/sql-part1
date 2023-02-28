CREATE TABLE Departments(
    name TEXT PRIMARY KEY,
    abrv TEXT NOT NULL UNIQUE
);

CREATE TABLE Programs(
    name TEXT PRIMARY KEY,
    abrv TEXT NOT NULL
);

CREATE TABLE Students(
    idnr CHAR(10) PRIMARY KEY,
    name TEXT NOT NULL,
    login TEXT NOT NULL UNIQUE,
    program TEXT NOT NULL,
    FOREIGN KEY (program) REFERENCES Programs(name),
    CONSTRAINT idnr_program_unique UNIQUE (program, idnr) -- for the sake of studentbranch table
);

CREATE TABLE Branches(
    name TEXT,
    program TEXT,
    PRIMARY KEY (name, program),
    FOREIGN KEY (program) REFERENCES Programs(name)
);

CREATE TABLE Courses(
    code CHAR(6) PRIMARY KEY,
    name TEXT NOT NULL,
    credits FLOAT NOT NULL CHECK (credits >= 0),
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
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program),
    FOREIGN KEY (student, program) REFERENCES Students(idnr, program)
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
    FOREIGN KEY (course) REFERENCES LimitedCourses(code),
    CONSTRAINT course_position_unique UNIQUE (course, position)
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
/* BasicInformation(idnr, name, login, program, branch): 
for all students, their national identification number, name, login, their program and the branch (if any). 
The branch column is the only column in any of the views that is allowed to contain NULL.
*/
CREATE OR REPLACE VIEW BasicInformation AS (
    SELECT Students.idnr, Students.name, Students.login, Students.program, StudentBranches.branch
    FROM Students
    LEFT JOIN StudentBranches
    ON Students.idnr = StudentBranches.student
);

/* FinishedCourses(student, course, grade, credits): for all students,
all finished courses,
along with their codes,
grades (
    'U',
    '3',
    '4'
    or '5'
)
and number of credits.The type of the grade should be a character type,
e.g.CHAR(1). */
CREATE OR REPLACE VIEW FinishedCourses AS (
    SELECT Taken.student, Taken.course, Taken.grade, Courses.credits 
    FROM Taken
    LEFT JOIN Courses
    ON Taken.course = Courses.code
);

/*PassedCourses(student, course, credits): for all students,
all passed courses,
i.e.courses finished with a grade other than 'U',
and the number of credits for those courses.This view is intended as a helper view towards later views (
    and for part 4), and will not be directly used by your application. */
CREATE OR REPLACE VIEW PassedCourses AS (
    SELECT FinishedCourses.student, FinishedCourses.course, FinishedCourses.credits
    FROM FinishedCourses
    WHERE grade != 'U'
);

/* 
Registrations(student, course, status): all registered
and waiting students for all courses,
along with their waiting status (
    'registered'
    or 'waiting'
).
*/
CREATE OR REPLACE VIEW Registrations AS (
    SELECT WaitingList.student, WaitingList.course, 'waiting' AS status
    FROM WaitingList
    UNION
    SELECT Registered.student, Registered.course, 'registered' AS status
    FROM Registered
    
);

/*
UnreadMandatory(student, course): for all students,
the mandatory courses (branch and program) they have not passed yet.
This view is intended as a helper view towards the PathToGraduation view,
and will not be directly used by your application.
*/
CREATE OR REPLACE VIEW UnreadMandatory AS (
    (SELECT Students.idnr AS student, MandatoryProgram.course
    FROM Students, MandatoryProgram
    WHERE Students.program = MandatoryProgram.program 
    AND (MandatoryProgram.course 
    NOT IN (SELECT PassedCourses.course 
    FROM PassedCourses 
    WHERE Students.idnr = PassedCourses.student)))
    UNION
    (SELECT Students.idnr AS student, MandatoryBranch.course
    FROM StudentBranches, MandatoryBranch, Students
    WHERE (Students.idnr, StudentBranches.branch, StudentBranches.program) 
    = (StudentBranches.student, MandatoryBranch.branch, MandatoryBranch.program)
    AND (MandatoryBranch.course
    NOT IN (SELECT PassedCourses.course 
    FROM PassedCourses 
    WHERE StudentBranches.student = PassedCourses.student)))
);
/*
PathToGraduation(
    student,
    totalCredits,
    mandatoryLeft,
    mathCredits,
    researchCredits,
    seminarCourses,
    qualified
): for all students,
their path to graduation,
i.e.a view with columns for: 
    student: the student 's national identification number;
    totalCredits: the number of credits they have taken;
    mandatoryLeft: the number of courses that are mandatory for a branch or a program they have yet to read;
    mathCredits: the number of credits they have taken in courses that are classified as math courses;
    researchCredits: the number of credits they have taken in courses that are classified as research courses;
    seminarCourses: the number of seminar courses they have passed;
    qualified: whether or not they qualify for graduation. The SQL type of this field should be BOOLEAN (i.e. TRUE or FALSE).
*/
CREATE OR REPLACE VIEW PathToGraduation AS (
    SELECT
    Students.idnr as student,
    COALESCE(totalCredits, 0) AS totalCredits,
    COALESCE(mandatoryLeft, 0) AS mandatoryLeft,
    COALESCE(mathCredits, 0) AS mathCredits,
    COALESCE(researchCredits, 0) AS researchCredits,
    COALESCE(seminarCourses, 0) AS seminarCourses,
    COALESCE((mathCredits >= 20 
    AND COALESCE(researchCredits, 0) >= 10 
    AND COALESCE(seminarCourses, 0) >= 1 
    AND COALESCE(mandatoryLeft, 0) = 0
    AND COALESCE(recommendedCredits, 0) >= 10), FALSE) AS qualified
    FROM
    Students
    LEFT OUTER JOIN
    (SELECT PassedCourses.student, SUM (credits) AS totalCredits 
    FROM PassedCourses 
    GROUP BY PassedCourses.student)
    totalCredits
    ON Students.idnr = totalCredits.student
    LEFT OUTER JOIN
    (SELECT UnreadMandatory.student, COUNT (course) AS mandatoryLeft
    FROM UnreadMandatory
    GROUP BY UnreadMandatory.student)
    mandatoryLeft
    ON Students.idnr = mandatoryLeft.student
    LEFT OUTER JOIN
    (SELECT PassedCourses.student, SUM (credits) AS mathCredits
    FROM PassedCourses, Classified
    WHERE PassedCourses.course = Classified.course AND Classified.classification = 'math'
    GROUP BY PassedCourses.student)
    mathCredits
    ON Students.idnr = mathCredits.student
    LEFT OUTER JOIN
    (SELECT PassedCourses.student, SUM (credits) AS researchCredits
    FROM PassedCourses, Classified
    WHERE PassedCourses.course = Classified.course AND Classified.classification = 'research'
    GROUP BY PassedCourses.student)
    researchCredits
    ON Students.idnr = researchCredits.student
    LEFT OUTER JOIN
    (SELECT PassedCourses.student, COUNT (PassedCourses.course) AS seminarCourses
    FROM PassedCourses, Classified
    WHERE PassedCourses.course = Classified.course AND Classified.classification = 'seminar'
    GROUP BY PassedCourses.student)
    seminarCourses
    ON Students.idnr = seminarCourses.student
    LEFT OUTER JOIN
    (SELECT PassedCourses.student, SUM (credits) AS recommendedCredits
    FROM RecommendedBranch, PassedCourses, StudentBranches
    WHERE PassedCourses.course = RecommendedBranch.course 
    AND StudentBranches.student = PassedCourses.student 
    AND StudentBranches.branch = RecommendedBranch.branch 
    AND StudentBranches.program = RecommendedBranch.program
    GROUP BY PassedCourses.student)
    recommendedCredits
    ON Students.idnr = recommendedCredits.student
);

INSERT INTO Programs VALUES ('Prog1', 'P1');
INSERT INTO Programs VALUES ('Prog2', 'P2');

INSERT INTO Branches VALUES ('B1','Prog1');
INSERT INTO Branches VALUES ('B2','Prog1');
INSERT INTO Branches VALUES ('B1','Prog2');


INSERT INTO Departments VALUES ('Dep1', 'D1');
INSERT INTO Departments VALUES ('Dep2', 'D2');


INSERT INTO PartOfDepartment VALUES ('Prog1','Dep1');
INSERT INTO PartOfDepartment VALUES ('Prog2','Dep2');
INSERT INTO PartOfDepartment VALUES ('Prog1','Dep2');


INSERT INTO Students VALUES ('1111111111','N1','ls1','Prog1');
INSERT INTO Students VALUES ('2222222222','N2','ls2','Prog1');
INSERT INTO Students VALUES ('3333333333','N3','ls3','Prog2');
INSERT INTO Students VALUES ('4444444444','N4','ls4','Prog1');
INSERT INTO Students VALUES ('5555555555','Nx','ls5','Prog2');
INSERT INTO Students VALUES ('6666666666','Nx','ls6','Prog2');



INSERT INTO Courses VALUES ('CCC111','C1',22.5,'Dep1');
INSERT INTO Courses VALUES ('CCC222','C2',20,'Dep1');
INSERT INTO Courses VALUES ('CCC333','C3',30,'Dep1');
INSERT INTO Courses VALUES ('CCC444','C4',60,'Dep1');
INSERT INTO Courses VALUES ('CCC555','C5',50,'Dep1');


INSERT INTO LimitedCourses VALUES ('CCC222',1);
INSERT INTO LimitedCourses VALUES ('CCC333',2);
INSERT INTO LimitedCourses VALUES ('CCC555',2);


INSERT INTO Classifications VALUES ('math');
INSERT INTO Classifications VALUES ('research');
INSERT INTO Classifications VALUES ('seminar');

INSERT INTO Classified VALUES ('CCC333','math');
INSERT INTO Classified VALUES ('CCC444','math');
INSERT INTO Classified VALUES ('CCC444','research');
INSERT INTO Classified VALUES ('CCC444','seminar');


INSERT INTO StudentBranches VALUES ('2222222222','B1','Prog1');
INSERT INTO StudentBranches VALUES ('3333333333','B1','Prog2');
INSERT INTO StudentBranches VALUES ('4444444444','B1','Prog1');
INSERT INTO StudentBranches VALUES ('5555555555','B1','Prog2');

INSERT INTO MandatoryProgram VALUES ('CCC111','Prog1');

INSERT INTO MandatoryBranch VALUES ('CCC333', 'B1', 'Prog1');
INSERT INTO MandatoryBranch VALUES ('CCC444', 'B1', 'Prog2');

INSERT INTO RecommendedBranch VALUES ('CCC222', 'B1', 'Prog1');
INSERT INTO RecommendedBranch VALUES ('CCC333', 'B1', 'Prog2');

INSERT INTO Registered VALUES ('1111111111','CCC111');
INSERT INTO Registered VALUES ('1111111111','CCC222');
INSERT INTO Registered VALUES ('1111111111','CCC333');
INSERT INTO Registered VALUES ('2222222222','CCC222');
INSERT INTO Registered VALUES ('5555555555','CCC222');
INSERT INTO Registered VALUES ('5555555555','CCC333');
INSERT INTO Registered VALUES ('5555555555','CCC555');


INSERT INTO Taken VALUES('4444444444','CCC111','5');
INSERT INTO Taken VALUES('4444444444','CCC222','5');
INSERT INTO Taken VALUES('4444444444','CCC333','5');
INSERT INTO Taken VALUES('4444444444','CCC444','5');

INSERT INTO Taken VALUES('5555555555','CCC111','5');
INSERT INTO Taken VALUES('5555555555','CCC222','4');
INSERT INTO Taken VALUES('5555555555','CCC444','3');

INSERT INTO Taken VALUES('2222222222','CCC111','U');
INSERT INTO Taken VALUES('2222222222','CCC222','U');
INSERT INTO Taken VALUES('2222222222','CCC444','U');

INSERT INTO PreRequisites VALUES('CCC111', 'CCC444');

--used timestamp instead, no 3rd argument needed
INSERT INTO WaitingList VALUES('3333333333','CCC222');
INSERT INTO WaitingList VALUES('3333333333','CCC333');
INSERT INTO WaitingList VALUES('2222222222','CCC333');
