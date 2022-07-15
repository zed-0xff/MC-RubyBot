package net.fabricmc.example;

import java.io.IOException;
import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientLifecycleEvents;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.minecraft.client.MinecraftClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ExampleMod implements ModInitializer {
    // This logger is used to write text to the console and the log file.
    // It is considered best practice to use your mod id as the logger's name.
    // That way, it's clear which mod wrote info, warnings, and errors.
    public static final Logger LOGGER = LoggerFactory.getLogger("modid");

    @Override
    public void onInitialize() {
        // This code runs as soon as Minecraft is in a mod-load-ready state.
        // However, some things (like resources) may still be uninitialized.
        // Proceed with mild caution.

        ClientLifecycleEvents.CLIENT_STARTED.register(this::clientReady);
        ClientTickEvents.END_CLIENT_TICK.register(this::clientTickEvent);
    }

    private void clientReady(MinecraftClient client) {
        try {
            GdmcHttpServer.startServer(client);
        } catch (IOException e) {
            LOGGER.warn("Unable to start server!");
        }
    }

    private void clientTickEvent(MinecraftClient mc) {
        if (mc.player == null || mc.world == null) {
            return;
        }
    }
}
