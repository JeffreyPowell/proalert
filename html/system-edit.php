<!DOCTYPE HTML>
<html>
<head>
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
    #print_r($_GET);
    $SYSTEM_ID = $_GET['id'];
    #echo $DEVICE_ID;
    #echo $_SERVER["REQUEST_METHOD"];
        
    if ($_SERVER["REQUEST_METHOD"] == "POST" ) {
        if ( isset($_POST["save"]) ) {
            #echo "#### save ####";
            $POST_SYSTEM_NAME = str_replace( "'", " ", $_POST["name"]);
            $POST_SYSTEM_URL = str_replace( " ", "", $_POST["url"]);
            // Create connection
            $conn = mysqli_connect($servername, $username, $password, $dbname);
            // Check connection
            if (!$conn) {
                die("<br><br>Connection failed: " . mysqli_connect_error());
            }
            # Update system with post data
            $sql = "UPDATE systems SET name = '$POST_SYSTEM_NAME', url = '$POST_SYSTEM_URL' WHERE id='$SYSTEM_ID';";
            #echo $sql;
            if (mysqli_query($conn, $sql)) {
                    #echo "<br><br>System updated successfully";
            } else {
                echo "<br><br>Error: " . $sql . "<br>" . mysqli_error($conn);
            }
            mysqli_close($conn);
        }
    }
    // Create connection
    $conn = mysqli_connect($servername, $username, $password, $dbname);
    // Check connection
    if (!$conn) {
        die("<br><br>Connection failed: " . mysqli_connect_error());
    }
    echo '<form method="post" action="'.htmlspecialchars($_SERVER["PHP_SELF"]).'?id='.$SYSTEM_ID.'">';
    $sql = "SELECT * FROM network WHERE id=".$NETDEV_ID;
    #echo $sql;
    $result = mysqli_query($conn, $sql);
    #print_r( $result );
    if (mysqli_num_rows($result) == 0) {
        echo "0 results";
    }
    $row = mysqli_fetch_assoc($result);
    $NETDEV_NAME = htmlentities($row["name"]);
    $NETDEV_MAC = $row["mac"];
    echo "<span class='ptitle'>EDIT Network Device '$NETDEV_NAME'</span><br><br>";
    echo "<table class='ttab'>";
    echo "<tr><td>";
    echo "<span class='tspan'>Name</span><br>";
    echo "<input type='text' name='name' value='".$NETDEV_NAME."' class='itextbox'><br><br>";
    echo "</td></tr><tr><td>";
    echo "<span class='tspan'>MAC Address</span><br>";
    echo "<input type='text' name='mac' value='$NETDEV_MAC' class='itextbox'><br><br>";
    echo "</td></tr>";
    echo "</table>";
    echo "<input type='submit' name='save' value='Save' class='bgreen' />";
    echo "&nbsp;&nbsp;";
    echo "<input type='button' onclick='location.href=\"/netdevices-list.php\";' value='Done' class='bgrey' />";
    echo '</form>';
    
    mysqli_close($conn);
?>

</body>
</html>
