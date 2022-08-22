package net.fabricmc.example;

import java.util.*;
import java.util.concurrent.locks.ReentrantLock;

import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.gui.DrawableHelper;
import net.minecraft.client.gui.screen.Screen;

public class HudOverlay {

    public static boolean shouldClick = false;
    public static int clickX, clickY;
    
    private static class HudText {
        String[] lines;
        int x;
        int y;
        int color;
        int ttl;
        int width = 0;

        HudText(String text, int x, int y, int color, int ttl) {
            this.lines = text.split("\n");
            this.x = x;
            this.y = y;
            this.color = color;
            this.ttl = ttl;
        }
    }

    private static final ReentrantLock lock = new ReentrantLock();
    private static final HashMap<String, HudText> texts = new HashMap<String, HudText>();

    public static String addText(String key, int x, int y, int ttl, int color, String text) {
        try {
            lock.lock();
            if ( key == null || key.equals("") ){
                key = x + ":" + y;
            }
            texts.put(key, new HudText(text, x, y, color, ttl));
        } finally {
            lock.unlock();
        }
        return key;
    }

    public static void removeText(String key, int x, int y) {
        if ( key == null || key.equals("") ){
            key = x + ":" + y;
        }
        try {
            lock.lock();
            texts.remove(key);
        } finally {
            lock.unlock();
        }
    }

    public static void updateTextTTL(String key, int x, int y, int ttl) {
        if ( key == null || key.equals("") ){
            key = x + ":" + y;
        }
        try {
            lock.lock();
            HudText t = texts.get(key);
            if ( t != null ) {
                t.ttl = ttl;
            }
        } finally {
            lock.unlock();
        }
    }

    public static void onRenderGameOverlayPost(MatrixStack matrixStack, MinecraftClient mc, DrawableHelper dh) {
        if ( mc == null ) {
            mc = MinecraftClient.getInstance();
        }
        try {
            lock.lock();
            for(Iterator<Map.Entry<String, HudText>> it = texts.entrySet().iterator(); it.hasNext(); ) {
                Map.Entry<String, HudText> entry = it.next();
                HudText t = entry.getValue();

                int x = t.x;
                int y = t.y;

                if ( x < 0 ) {
                    if ( t.width == 0 ) {
                        for ( String line : t.lines ){
                            t.width = Math.max(t.width, mc.textRenderer.getWidth(line));
                        }
                    }
                    x = mc.getWindow().getScaledWidth() - t.width + x;
                }
                if ( y < 0 ) {
                     y = mc.getWindow().getScaledHeight() - (mc.textRenderer.fontHeight+1)*t.lines.length + y;
                }

                for ( String line : t.lines ){
                    dh.drawStringWithShadow( matrixStack, mc.textRenderer, line, x, y, t.color );
                    y += mc.textRenderer.fontHeight+1;
                }

                if( t.ttl != 0 ) {
                    if( t.ttl == 1 ) {
                        it.remove();
                    } else {
                        t.ttl--;
                    }
                }
            }
        } finally {
            lock.unlock();
        }

        if ( dh instanceof Screen ) {
            // clicks should be in render thread
            if (shouldClick) {
                int button = 0; // left
                ((Screen)dh).mouseClicked(clickX, clickY, button);
            }
        }
    }
}
