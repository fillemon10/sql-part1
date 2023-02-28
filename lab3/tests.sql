-- TEST #1: Register for an unlimited course.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('2222222222', 'CCC444');

-- TEST #2: Register an already registered student.
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('2222222222', 'CCC444');

-- TEST #3: Unregister from an unlimited course.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations where student = '2222222222' AND course = 'CCC444';

-- TEST #4: Unregister again from an unlimited course.
-- EXPECTED OUTCOME: Fail
DELETE FROM Registrations where student = '2222222222' AND course = 'CCC444';

-- TEST #5: Register to limited course.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('4444444444', 'CCC555');

-- TEST #6: Try to register for course already passed.
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('4444444444', 'CCC222');

-- TEST #7: Unregister from a limited course without waiting list.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations where student = '4444444444' AND course = 'CCC555';

-- TEST #8: Unregister from a limited course with waiting list while being in the middle of the waiting list.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations where student = '2222222222' AND course = 'CCC333';

-- TEST #9: Unregister from a limited course with a waiting list while being registered.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations where student = '1111111111' AND course = 'CCC333';

-- TEST #10: Register the student that was unregistered from the limited course to see if the position in the waiting list is correct
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('1111111111', 'CCC333');

-- TEST #11: Unregister from an overfull course with waiting list while being registered.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations where student = '1111111111' AND course = 'CCC222';

-- TEST #12: Wait for limited course.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('6666666666', 'CCC222');

-- TEST #13: Try to register for a course where the prerequisites haven't been taken.
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('2222222222', 'CCC111');

-- TEST #14: Try to register for a course where the prerequisites has been taken.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('6666666666', 'CCC111');

-- TEST #15: Unregister to setup test #16
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations where student = '2222222222' AND course = 'CCC555';

-- TEST #16: Re-register same student for the same limited course. Check that the student is first removed then ends up in the same position in the waiting list.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('2222222222', 'CCC555');

-- TEST #17: Try to register again for the same limited course while being in the waiting list.
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('2222222222', 'CCC555');
