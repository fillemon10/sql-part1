
import java.sql.*; // JDBC stuff.
import java.util.Properties;
import org.json.JSONArray;
import org.json.JSONObject;

public class PortalConnection {

    // Set this to e.g. "portal" if you have created a database named portal
    // Leave it blank to use the default database of your database user
    static final String DBNAME = "portal";
    // For connecting to the portal database on your local machine
    static final String DATABASE = "jdbc:postgresql://localhost/"+DBNAME;
    static final String USERNAME = "postgres";
    static final String PASSWORD = "postgres";

    // For connecting to the chalmers database server (from inside chalmers)
    // static final String DATABASE = "jdbc:postgresql://brage.ita.chalmers.se/";
    // static final String USERNAME = "tda357_nnn";
    // static final String PASSWORD = "yourPasswordGoesHere";


    // This is the JDBC connection object you will be using in your methods.
    private Connection conn;

    public PortalConnection() throws SQLException, ClassNotFoundException {
        this(DATABASE, USERNAME, PASSWORD);  
    }

    // Initializes the connection, no need to change anything here
    public PortalConnection(String db, String user, String pwd) throws SQLException, ClassNotFoundException {
        Class.forName("org.postgresql.Driver");
        Properties props = new Properties();
        props.setProperty("user", user);
        props.setProperty("password", pwd);
        conn = DriverManager.getConnection(db, props);
    }


    // Register a student on a course, returns a tiny JSON document (as a String)
    public String register(String student, String courseCode){
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO Registrations VALUES(?,?)");) {
            ps.setString(1, student);
            ps.setString(2, courseCode);
            ps.executeUpdate();
            return "{\"success\":true}";
        } catch (SQLException e) {
           return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
        }
    }

    // Unregister a student from a course, returns a tiny JSON document (as a String)
    public String unregister(String student, String courseCode){
        try (Statement ps = conn.createStatement();) {
            int r = ps.executeUpdate("DELETE FROM Registrations WHERE student='" + student + "' AND course='" + courseCode + "'");
            if (r == 0) {
                return "{\"success\":false, \"error\":\"Student is not registered or waiting for this course.\"}";
            } else {
                return "{\"success\":true}";
            }
        } catch (SQLException e) {
            return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
        }
    }

    // Return a JSON document containing lots of information about a student, it should validate against the schema found in information_schema.json
    public String getInfo(String student) throws SQLException{
        
        JSONObject studentInfo = new JSONObject();

        // Get basic information
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT idnr AS student, name, login, program, branch FROM BasicInformation WHERE idnr=?")) {
            ps.setString(1, student);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                studentInfo.put("student", rs.getString("student"));
                studentInfo.put("name", rs.getString("name"));
                studentInfo.put("login", rs.getString("login"));
                studentInfo.put("program", rs.getString("program"));
                studentInfo.put("branch", rs.getString("branch"));
            }
        }

        // Get finished courses
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT Courses.name AS course, Courses.code, grade, Courses.credits " +
                        "FROM FinishedCourses JOIN Courses ON FinishedCourses.course = Courses.code " +
                        "WHERE student=?")) {
            ps.setString(1, student);
            ResultSet rs = ps.executeQuery();
            JSONArray finishedCourses = new JSONArray();
            while (rs.next()) {
                JSONObject courseInfo = new JSONObject();
                courseInfo.put("course", rs.getString("course"));
                courseInfo.put("code", rs.getString("code"));
                courseInfo.put("grade", rs.getString("grade"));
                courseInfo.put("credits", rs.getFloat("credits"));
                finishedCourses.put(courseInfo);
            }
            studentInfo.put("finished", finishedCourses);
        }

        // Get registered courses
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT Courses.name AS course, Courses.code AS code, Registrations.status AS status, COALESCE(CourseQueuePositions.place, NULL) AS position " +
                        "FROM Courses, Registrations " +
                        "FULL OUTER JOIN CourseQueuePositions ON Registrations.student = CourseQueuePositions.student AND Registrations.course = CourseQueuePositions.course " +
                        "WHERE Registrations.student = ? AND Registrations.course = Courses.code")) {
            ps.setString(1, student);
            ResultSet rs = ps.executeQuery();
            JSONArray registeredCourses = new JSONArray();
            while (rs.next()) {
                JSONObject courseInfo = new JSONObject();
                courseInfo.put("code", rs.getString("code"));
                courseInfo.put("course", rs.getString("course"));
                courseInfo.put("status", rs.getString("status"));
                courseInfo.put("position", rs.getFloat("position"));

                registeredCourses.put(courseInfo);
            }
            studentInfo.put("registered", registeredCourses);
        }

        // Get path to graduation
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT totalCredits, mandatoryLeft, mathCredits, researchCredits, seminarCourses, qualified " +
                        "FROM PathToGraduation WHERE student=?")) {
            ps.setString(1, student);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                studentInfo.put("totalCredits", rs.getFloat("totalCredits"));
                studentInfo.put("mandatoryLeft", rs.getInt("mandatoryLeft"));
                studentInfo.put("mathCredits", rs.getFloat("mathCredits"));
                studentInfo.put("researchCredits", rs.getFloat("researchCredits"));
                studentInfo.put("seminarCourses", rs.getInt("seminarCourses"));
                studentInfo.put("canGraduate", rs.getBoolean("qualified"));
            }
        }

        return studentInfo.toString();
    }

    // This is a hack to turn an SQLException into a JSON string error message. No need to change.
    public static String getError(SQLException e){
       String message = e.getMessage();
       int ix = message.indexOf('\n');
       if (ix > 0) message = message.substring(0, ix);
       message = message.replace("\"","\\\"");
       return message;
    }
}
