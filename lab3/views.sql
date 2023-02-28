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
