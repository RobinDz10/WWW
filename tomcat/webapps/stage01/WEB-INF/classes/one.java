import java.io.*;
import javax.servlet.*;
import javax.servlet.http.*;

public class one extends HttpServlet {
  public void doGet(HttpServletRequest request,
                    HttpServletResponse response) throws IOException, ServletException {
    String name = request.getParameter("who");
    String age = request.getParameter("age");
    int age1 = 0;
    for(int i = 0; i < age.length(); i++){
      age1 = age1 * 10 + age.charAt(i) - '0';
    }
    age1 += 1;

    response.setContentType("text/html");
    PrintWriter out = response.getWriter();
    out.println("Well, " + name + " you will be " + age1 + " next year.");
  }
}