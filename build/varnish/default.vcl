
backend web {
    .host = "web.logstashdemo.com";
    .port = "8080";
}

backend kibana {
    .host = "kibana.logstashdemo.com";
    .port = "5601";
}

backend elastic {
    .host = "localhost";
    .port = "9200";
}

# Direct traffic to correct nginx vhost
sub vcl_recv {
    if (req.http.host ==  "web.logstashdemo.com") {
        set req.backend = web;
    } elsif (req.http.host ==  "kibana.logstashdemo.com") {
        set req.backend = kibana;
    } elsif (req.http.host ==  "elastic.logstashdemo.com") {
        set req.backend = elastic;
    }
    return(pass);
}
