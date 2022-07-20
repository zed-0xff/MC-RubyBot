package net.fabricmc.example;

import net.fabricmc.example.handlers.StatusHandler;
import java.io.IOException;
import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientLifecycleEvents;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.command.v2.ClientCommandRegistrationCallback;
import net.fabricmc.fabric.api.client.command.v2.ClientCommandManager;
import net.minecraft.client.MinecraftClient;
import net.minecraft.text.Text;
import com.mojang.brigadier.CommandDispatcher;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ExampleMod implements ModInitializer {
    // This logger is used to write text to the console and the log file.
    // It is considered best practice to use your mod id as the logger's name.
    // That way, it's clear which mod wrote info, warnings, and errors.
    public static final Logger LOGGER = LoggerFactory.getLogger("modid");
	private static CommandDispatcher commandDispatcher;

    @Override
    public void onInitialize() {
        // This code runs as soon as Minecraft is in a mod-load-ready state.
        // However, some things (like resources) may still be uninitialized.
        // Proceed with mild caution.

        ClientLifecycleEvents.CLIENT_STARTED.register(this::clientReady);
        ClientTickEvents.END_CLIENT_TICK.register(this::clientTickEvent);
		ClientCommandRegistrationCallback.EVENT.register((dispatcher, registryAccess) -> {
            commandDispatcher = dispatcher;
            commandDispatcher.register(ClientCommandManager.literal("legit").executes(context -> {
                context.getSource().sendFeedback(Text.literal("This is a legit client command!"));
                return 0;
            }));
		});
    }

    public static void registerCommand(String command){
        commandDispatcher.register(ClientCommandManager.literal(command).executes(context -> {
            context.getSource().sendFeedback(Text.literal("This is a client command!"));
            return 0;
        }));
    }

    private void clientReady(MinecraftClient client) {
        try {
            GdmcHttpServer.startServer(client);
        } catch (IOException e) {
            LOGGER.warn("Unable to start server!");
        }
    }

    private static long lastLocRaw = 0;
    private void clientTickEvent(MinecraftClient mc) {
        if (mc.player == null || mc.world == null) {
            return;
        }
        if ( ((StatusHandler.locraw == null) || (StatusHandler.locraw.server.equals("limbo"))) && (System.currentTimeMillis() - lastLocRaw > 5000)) {
            lastLocRaw = System.currentTimeMillis();
            mc.player.sendChatMessage("/locraw");
        }
    }
}
