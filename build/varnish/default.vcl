
backend web {
    .host = "web.logstashdemo.com";
    .port = "8080";
}

backend kibana {
    .host = "logs.logstashdemo.com";
    .port = "8081";
}

backend elastic {
    .host = "localhost";
    .port = "9200";
}

# Direct traffic to correct nginx vhost
sub vcl_recv {
    if (req.http.host ==  "web.logstashdemo.com") {
        set req.backend = web;
    } elsif (req.http.host ==  "logs.logstashdemo.com") {
        set req.backend = kibana;
    } elsif (req.http.host ==  "elastic.logstashdemo.com") {
        set req.backend = elastic;
    }
    return(pass);
}
