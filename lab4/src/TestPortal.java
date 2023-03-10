public class TestPortal {

   // enable this to make pretty printing a bit more compact
   private static final boolean COMPACT_OBJECTS = false;

   // This class creates a portal connection and runs a few operation

   public static void main(String[] args) {
      try{
         PortalConnection c = new PortalConnection();
         //1
          prettyPrint(c.getInfo("2222222222"));
          pause();

          //2
          System.out.println(c.register("2222222222", "CCC444"));
          prettyPrint(c.getInfo("2222222222"));
          pause();

          //3
          System.out.println(c.register("2222222222", "CCC444"));
          pause();

          //4
          System.out.println(c.unregister("2222222222", "CCC444"));
          prettyPrint(c.getInfo("2222222222"));
          System.out.println(c.unregister("2222222222", "CCC444"));
          pause();

          //5
          System.out.println(c.register("2222222222", "CCC111"));
          pause();

          //6
          System.out.println(c.unregister("1111111111", "CCC333"));
          System.out.println(c.register("1111111111", "CCC333"));
          prettyPrint(c.getInfo("1111111111"));
          pause();

          //7
          System.out.println(c.unregister("2222222222", "CCC555"));
          System.out.println(c.register("2222222222", "CCC555"));
          prettyPrint(c.getInfo("2222222222"));
          pause();

          //8
          System.out.println(c.unregister("1111111111", "CCC222"));
          prettyPrint(c.getInfo("1111111111"));
          pause();

          //9
          System.out.println(c.unregister("1111111111", "CCC555'; DELETE FROM Registered WHERE 'a'='a'; DELETE FROM WaitingList WHERE 'a'='a"));

      
      } catch (ClassNotFoundException e) {
         System.err.println("ERROR!\nYou do not have the Postgres JDBC driver (e.g. postgresql-42.5.1.jar) in your runtime classpath!");
      } catch (Exception e) {
         e.printStackTrace();
      }
   }
   
   
   
   public static void pause() throws Exception{
     System.out.println("PRESS ENTER");
     while(System.in.read() != '\n');
   }
   
   // This is a truly horrible and bug-riddled hack for printing JSON. 
   // It is used only to avoid relying on additional libraries.
   // If you are a student, please avert your eyes.
   public static void prettyPrint(String json){
      System.out.print("Raw JSON:");
      System.out.println(json);
      System.out.println("Pretty-printed (possibly broken):");
      
      int indent = 0;
      json = json.replaceAll("\\r?\\n", " ");
      json = json.replaceAll(" +", " "); // This might change JSON string values :(
      json = json.replaceAll(" *, *", ","); // So can this
      
      for(char c : json.toCharArray()){
        if (c == '}' || c == ']') {
          indent -= 2;
          breakline(indent); // This will break string values with } and ]
        }
        
        System.out.print(c);
        
        if (c == '[' || c == '{') {
          indent += 2;
          breakline(indent);
        } else if (c == ',' && !COMPACT_OBJECTS) 
           breakline(indent);
      }
      
      System.out.println();
   }
   
   public static void breakline(int indent){
     System.out.println();
     for(int i = 0; i < indent; i++)
       System.out.print(" ");
   }   
}
