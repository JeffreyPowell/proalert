<!DOCTYPE HTML>  
<html>
<head>
<meta http-equiv="refresh" content="30">
<style>
    .pbody { background-color: #080808; font-family: courier; color: red; font-size: small;}
    .debug { font-family: courier; color: red; font-size: large; }
</style>
</head>
<body class='pbody'>

<?php
    
    ini_set('display_errors', 1);
    ini_set('display_startup_errors', 1);
    error_reporting(E_ALL);
 
    $ini_array = parse_ini_file("/opt/proalert/proalert-master/config.ini", true);
    
    $servername = $ini_array['db']['server'];
    $username =$ini_array['db']['user'];
    $password = $ini_array['db']['password'];
    $dbname = $ini_array['db']['database'];
    
    if ($_SERVER["REQUEST_METHOD"] == "POST") {
        if ( array_key_exists( 'add', $_POST ) ) {
            // Create connection
            $conn = mysqli_connect($servername, $username, $password, $dbname);
            // Check connection
            if (!$conn) {
                die("Connection failed: " . mysqli_connect_error());
                }
            $sql = "INSERT INTO systems (name, url) VALUES ('new system', '<url>')";
            if (!mysqli_query($conn, $sql)) {
                echo "Error: " . $sql . "<br>" . mysqli_error($conn);
            }
            mysqli_close($conn);
        }
        if ( array_key_exists( 'delete', $_POST ) ) {
            // Create connection
            $conn = mysqli_connect($servername, $username, $password, $dbname);
            // Check connection
            if (!$conn) {
                die("Connection failed: " . mysqli_connect_error());
            }
            $SYSTEM_ID = $_POST["system_id"];
            
            $sql = "DELETE FROM systems WHERE system_id='$SYSTEM_ID';";
            if (!mysqli_query($conn, $sql)) {
                echo "Error: " . $sql . "<br>" . mysqli_error($conn);
            }

            mysqli_close($conn);
        }
    }
    
    // Create connection
    $conn = mysqli_connect($servername, $username, $password, $dbname);
    // Check connection
    if (!$conn) {
        die("Connection failed: " . mysqli_connect_error());
    }
    $sql = "SELECT * FROM systems order by name asc";
    $result = mysqli_query($conn, $sql);
    if (mysqli_num_rows($result) > 0) {
        // output data of each row
        echo "<span class='ptitle'>Customer Systems</span><br><br>";
        echo "<table class='ttab' ><tr>";
        echo "<th class='tcol'><span class='tspan'>Name</span></th>";     
        echo "<th width=1%><span class='tspan'>URL</span></th>";
        echo "<th width=1%><span class='tspan'>Status</span></th>";
        echo "<th width=1%></th><th width=1%></th>";
        echo "</tr>";
        while($row = mysqli_fetch_assoc($result)) {
            $SYSTEM_ID = $row["id"];
            $SYSTEM_NAME = $row["name"];
            $SYSTEM_URL = $row["url"];
            $SYSTEM_STATUS = $row["status"];
            echo "<tr>";
            echo "<td class='dcolname' ><span class='dspan'>".$SYSTEM_NAME."</span></td>";
            echo "<td class='dcolname' ><span class='dspan'>".$SYSTEM_URL."</span></td>";
            echo "<td class='dcolstatus' ><span class='dspan'>".$SYSTEM_STATUS."</span></td>";
 
            echo "<td>";
            echo "<input type='button' onclick='location.href=\"/system-edit.php?id=$SYSTEM_ID\";' value='Edit' class='bblue' />";
            echo "</td>";
            echo "<td><form method='post' action='/system-list.php'>";
            echo "<input type='hidden' name='system_id' value='".$SYSTEM_ID."' />";
            echo "<input type='submit' name='delete' value='Delete' class='bred' /></form></td>";
            echo "</tr>";
        }    
        echo "</table>";
    } else {
        echo "<span class='ptitle'>No Available Systems</span><br><br>";
    }
    mysqli_close($conn);
    
?>  

<form method='post' action='systems-list.php'>
<input type='submit' name='add' value='Add new' class='bgreen' />
<input type='button' onclick='location.href="/dashboard.php";' value='Done' class='bgrey' />
</form>

</body>
</html>
