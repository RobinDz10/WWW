<?
$servername = "localhost";
$username = "whoever";
$database = "whatever";
$password="wha55up";
$port = "26262";
$socket = "/u/duozwang/a348-spring-2021-workspace/mysql/mysql.sock";

// Create connection
$mysqli = new mysqli($servername, $username, $password, $database, $port, $socket);
  if ($mysqli) {
      echo "I can select the database. <p>";
      $query = "select * from players"; // table of interest  
      $result = $mysqli->query($query);
      if (! $result) echo "I don't see anything in here. <p>";
      else { 
        $num_cats = $result -> num_rows;
        echo "There are " . $num_cats . " records I can see. <p>";
        while ($row = $result->fetch_row()) {
          echo "(" . $row[0] . ", " . $row[1] . ") <p> ";
        }
      } 
  } else {
    echo "I cannot connect. <p>";
  }
?>

