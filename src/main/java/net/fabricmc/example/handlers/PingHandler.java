package net.fabricmc.example.handlers;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import java.io.IOException;
import java.io.OutputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.FileOutputStream;
import java.util.*;

public class PingHandler implements HttpHandler {
	@Override    
	public void handle(HttpExchange http) throws IOException {
        String body = "PONG";
        int status = 200;

        byte[] bytes = body.getBytes();
        http.sendResponseHeaders(status, bytes.length);

        OutputStream os = http.getResponseBody();
        os.write(bytes);
        os.close();
	}
}
