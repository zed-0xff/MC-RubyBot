package net.fabricmc.example;

import net.fabricmc.example.utils.BlockBreakHelper;

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
import org.apache.commons.lang3.time.StopWatch;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.TimeUnit;

public class ExampleMod implements ModInitializer {
    public static final String MOD_ID = "ExternalBrainz";
    public static final Logger LOGGER = LoggerFactory.getLogger("modid");
    public static ModConfig CONFIG = null;
    public static int tick = 0;

    public static StopWatch tickStart = new StopWatch();

    public static boolean shouldLockCursor = false;
    public static boolean shouldUnlockCursor = false;
    public static boolean shouldCloseScreen = false;

	private static CommandDispatcher commandDispatcher;
    private static MinecraftClient mc = null;

    private static ArrayBlockingQueue<Runnable> queue = new ArrayBlockingQueue<>(50);
    private static long renderThreadId;

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
        for( int port = 9999; port < 10010; port++ ) {
            try {
                GdmcHttpServer.startServer(client, port);
                break;
            } catch (IOException e) {
                LOGGER.warn("Unable to start server at port " + port + " !");
            }
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

    public static boolean inRenderThread(){
        return renderThreadId == Thread.currentThread().getId();
    }

    public static void enqueue(Runnable r) {
        queue.add(r);
    }

    // GUI tasks should be run in the render thread
    // or exception 'Rendersystem called from wrong thread' will occur
    private void processRunnables() {
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

        //if ( queue.size() > 0 ) {
            int n = 0;
            Runnable r;
            try {
                while ( (r = queue.poll(CONFIG.queuePollTimeout, TimeUnit.MILLISECONDS)) != null ) {
                    n += 1;
                    r.run();
                }
            } catch ( InterruptedException e ) {
                LOGGER.error("[?] " + e);
            }
            if ( CONFIG.debug && n > 0 ) {
                LOGGER.info("[d] [" + tick + "] ran " + n + " runnables");
            }
        //}
    }

    private void logInputEvents() {
        for ( InputUtil.Key key : monitoredKeys ) {
            StatusHandler.logInputEvent( key.toString(), InputUtil.isKeyPressed(mc.getWindow().getHandle(), key.getCode()) ? 1 : 0 );
        }
        StatusHandler.logInputEvent( "key.mouse.left", mc.mouse.wasLeftButtonClicked() ? 1 : 0 );
        StatusHandler.logInputEvent( "key.mouse.right", mc.mouse.wasRightButtonClicked() ? 1 : 0 );
        StatusHandler.logInputEvent( "mouse.x", (int)mc.mouse.getX());
        StatusHandler.logInputEvent( "mouse.y", (int)mc.mouse.getY());
    }

    private void clientTickEvent(MinecraftClient mc) {
        tickStart.reset();
        tickStart.start();
        tick++;
        renderThreadId = Thread.currentThread().getId();
        if (mc.player == null || mc.world == null) {
            return;
        }

        this.mc = mc;

        BlockBreakHelper.tick(mc);
        logInputEvents();
        processRunnables();
    }
}
