CREATE OR REPLACE VIEW CourseQueuePositions AS
(
    SELECT Courses.code as course, WaitingList.student as student, RANK() OVER (PARTITION BY WaitingList.course ORDER BY WaitingList.position) AS place
    FROM Courses, WaitingList
    WHERE Courses.code = WaitingList.course
);


CREATE FUNCTION regtrig() RETURNS trigger AS $regtrig$
    BEGIN
        
        IF EXISTS(SELECT * FROM Registrations WHERE student = NEW.student AND course = NEW.course) THEN 
            RAISE EXCEPTION '% is already registered or waiting for %', NEW.student, NEW.course;
        END IF;
        
        IF EXISTS(SELECT * FROM PreRequisites WHERE course = NEW.course AND prerequisiteCourse NOT IN (SELECT course FROM PassedCourses WHERE student = NEW.student)) THEN
            RAISE EXCEPTION 'Prerequisites for % not passed by %', NEW.course, NEW.student;
        END IF;

        
        IF EXISTS(SELECT * FROM PassedCourses WHERE student = NEW.student AND course = NEW.course) THEN
            RAISE EXCEPTION '% has already passed %', NEW.student, NEW.course;
        END IF;

        IF (SELECT COUNT(student) FROM Registered WHERE NEW.course = course) >= (SELECT capacity FROM LimitedCourses WHERE NEW.course = code) THEN 
            INSERT INTO WaitingList VALUES (NEW.student, NEW.course);
            RETURN NEW;
        END IF;
        
        INSERT INTO Registered VALUES (NEW.student, NEW.course);
        RETURN NEW;
        

    END;
$regtrig$ LANGUAGE plpgsql;

CREATE TRIGGER regtrig INSTEAD OF INSERT OR UPDATE ON Registrations
    FOR EACH ROW EXECUTE FUNCTION regtrig();


CREATE FUNCTION unregtrig() RETURNS trigger AS $unregtrig$
    DECLARE
        first_student VARCHAR(10);
    BEGIN
        IF EXISTS(SELECT * FROM Registrations WHERE status = 'registered' AND OLD.student = student AND OLD.course = course) THEN
            
            DELETE FROM Registered WHERE OLD.student = student AND OLD.course = course;
            IF (SELECT COUNT(student) FROM Registered WHERE OLD.course = course) <= (SELECT capacity FROM LimitedCourses WHERE OLD.course = code)
                THEN 
                IF EXISTS(SELECT student FROM CourseQueuePositions WHERE course = OLD.course AND place = 1)
                THEN 
                    first_student :=  (SELECT student FROM CourseQueuePositions WHERE course = OLD.course AND place = 1);
                    DELETE FROM WaitingList WHERE student = first_student AND course = OLD.course;
                    INSERT INTO Registered VALUES (first_student, OLD.course);
                END IF;
                
            END IF;
        END IF;
        IF EXISTS(SELECT * FROM Registrations WHERE status = 'waiting' AND OLD.student = student AND OLD.course = course) THEN
            DELETE FROM WaitingList WHERE OLD.student = student AND OLD.course = course;
        END IF;
        RETURN OLD;
    END;
$unregtrig$ LANGUAGE plpgsql;

CREATE TRIGGER unregtrig INSTEAD OF DELETE ON Registrations
    FOR EACH ROW EXECUTE PROCEDURE unregtrig();
