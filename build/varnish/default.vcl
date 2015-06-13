
backend web {
    .host = "web.logstashdemo.com";
    .port = "8080";
}

backend kibana {
    .host = "logs.logstashdemo.com";
    .port = "8081";
}

# Direct traffic to correct nginx vhost
sub vcl_recv {
    if (req.http.host ==  "web.logstashdemo.com") {
        set req.backend = web;
    } elsif (req.http.host ==  "logs.logstashdemo.com") {
        set req.backend = kibana;
    }
}
