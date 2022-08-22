package net.fabricmc.example;

import com.mojang.brigadier.CommandDispatcher;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import me.shedaniel.autoconfig.AutoConfig;
import me.shedaniel.autoconfig.serializer.JanksonConfigSerializer;
import net.fabricmc.api.ModInitializer;
import net.fabricmc.example.handlers.StatusHandler;
import net.fabricmc.fabric.api.client.command.v2.ClientCommandManager;
import net.fabricmc.fabric.api.client.command.v2.ClientCommandRegistrationCallback;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientLifecycleEvents;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.Mouse;
import net.minecraft.client.world.ClientWorld;
import net.minecraft.client.util.InputUtil;
import net.minecraft.text.Text;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ExampleMod implements ModInitializer {
    public static final String MOD_ID = "ExternalBrainz";
    public static final Logger LOGGER = LoggerFactory.getLogger("modid");
    public static ModConfig CONFIG = null;
    public static int tick = 0;

    public static boolean shouldLockCursor = false;
    public static boolean shouldUnlockCursor = false;
    public static boolean shouldCloseScreen = false;

	private static CommandDispatcher commandDispatcher;

    @Override
    public void onInitialize() {
        ExampleMod.CONFIG = AutoConfig.register(ModConfig.class, JanksonConfigSerializer::new).getConfig();

        ClientLifecycleEvents.CLIENT_STARTED.register(this::clientReady);
        ClientTickEvents.END_CLIENT_TICK.register(this::clientTickEvent);
//        ClientTickEvents.END_WORLD_TICK.register(this::worldTickEvent);
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
            StatusHandler.onCommand(command);
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
    private static List<InputUtil.Key> monitoredKeys = new ArrayList<InputUtil.Key>(Arrays.asList(
                InputUtil.fromTranslationKey("key.keyboard.w"),
                InputUtil.fromTranslationKey("key.keyboard.s"),
                InputUtil.fromTranslationKey("key.keyboard.a"),
                InputUtil.fromTranslationKey("key.keyboard.d"),
                InputUtil.fromTranslationKey("key.keyboard.escape"),
                InputUtil.fromTranslationKey("key.keyboard.space"),
                InputUtil.fromTranslationKey("key.keyboard.left.control"),
                InputUtil.fromTranslationKey("key.keyboard.left.shift")
                ));

    // GUI tasks should be run in the render thread
    // or exception 'Rendersystem called from wrong thread' will occur
    private void processGuiTasks(MinecraftClient mc) {
        if (shouldLockCursor) {
            mc.mouse.lockCursor();
            shouldLockCursor = false;
        }

        if (shouldUnlockCursor) {
            mc.mouse.unlockCursor();
            shouldUnlockCursor = false;
        }

        if (shouldCloseScreen) {
            if ( mc.currentScreen != null )
                mc.currentScreen.close();
            shouldCloseScreen = false;
        }

    }

//    private void worldTickEvent(ClientWorld world) {
//        LOGGER.info("[d] worldTickEvent");
//    }

    private void clientTickEvent(MinecraftClient mc) {
        tick++;
        if (mc.player == null || mc.world == null) {
            return;
        }

        processGuiTasks(mc);

//        if ( ((StatusHandler.locraw == null) || (StatusHandler.locraw.server.equals("limbo"))) && (System.currentTimeMillis() - lastLocRaw > 5000)) {
//            lastLocRaw = System.currentTimeMillis();
//            mc.player.sendChatMessage("/locraw", null);
//        }
        for ( InputUtil.Key key : monitoredKeys ) {
            StatusHandler.logInputEvent( key.toString(), InputUtil.isKeyPressed(mc.getWindow().getHandle(), key.getCode()) ? 1 : 0 );
        }
        StatusHandler.logInputEvent( "key.mouse.left", mc.mouse.wasLeftButtonClicked() ? 1 : 0 );
        StatusHandler.logInputEvent( "key.mouse.right", mc.mouse.wasRightButtonClicked() ? 1 : 0 );
        StatusHandler.logInputEvent( "mouse.x", (int)mc.mouse.getX());
        StatusHandler.logInputEvent( "mouse.y", (int)mc.mouse.getY());
    }
}
