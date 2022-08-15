package net.fabricmc.example;

import net.fabricmc.example.handlers.*;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.minecraft.client.MinecraftClient;

public class GdmcHttpServer {
    private static HttpServer httpServer = null;
    private static MinecraftClient mc;
    public static final Logger LOGGER = LoggerFactory.getLogger("modid");

    private static final String HOST = "localhost";
    private static final int    PORT = 9999;

    public static void startServer(MinecraftClient mc) throws IOException {
        GdmcHttpServer.mc = mc;

        if ( httpServer == null ) {
            httpServer = HttpServer.create(new InetSocketAddress(HOST, PORT), 0);
            httpServer.setExecutor(null);
            createContexts();
            LOGGER.info("[.] HTTP server starting on http://" + HOST + ":" + PORT);
            httpServer.start();
            LOGGER.info("[.] HTTP server started on http://" + HOST + ":" + PORT);
        } else {
            LOGGER.warn("[?] HTTP server already started on http://" + HOST + ":" + PORT);
        }
    }

//    public static void stopServer() {
//        if(httpServer != null) {
//            httpServer.stop(5);
//        }
//    }

    private static void createContexts() {
        httpServer.createContext("/", new StatusHandler(mc));
        httpServer.createContext("/action", new ActionHandler(mc));
//        httpServer.createContext("/command", new CommandHandler(mc));
//        httpServer.createContext("/chunks", new ChunkHandler(mc));
//        httpServer.createContext("/blocks", new BlocksHandler(mc));
//        httpServer.createContext("/buildarea", new BuildAreaHandler(mc));
    }
}
