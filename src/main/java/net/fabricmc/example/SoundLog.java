package net.fabricmc.example;

import java.util.Vector;
import java.util.concurrent.locks.ReentrantLock;

import com.google.gson.*;

import net.minecraft.client.sound.SoundInstance;

class SoundLog {

    static class LogEntry {
        int index; // there ARE multiple sounds per tick
        int tick;
        SoundInstance sound;

        LogEntry(int index, int tick, SoundInstance sound) {
            this.index = index;
            this.tick = tick;
            this.sound = sound;
        }

        JsonObject serialize() {
            JsonObject obj = new JsonObject();
            obj.addProperty("index", index);
            obj.addProperty("tick", tick);
            obj.addProperty("id", sound.getId().toString());
            obj.addProperty("pitch", sound.getPitch());
            obj.addProperty("volume", sound.getVolume());
            if (sound.isRelative()) {
                obj.addProperty("relative", sound.isRelative());
            }
            obj.addProperty("x", sound.getX());
            obj.addProperty("y", sound.getY());
            obj.addProperty("z", sound.getZ());
            // a sound can also have Entity / ClientPlayerEntity (for elytra)
            return obj;
        }
    }

    private static final ReentrantLock lock = new ReentrantLock();
    private static final Vector<LogEntry> log = new Vector<LogEntry>();
    private static int index = 0;


    public static void add( SoundInstance sound ) {
        if ( sound == null ) return;

        try {
            lock.lock();
            log.add(new LogEntry(index++, ExampleMod.tick, sound));
            if ( log.size() > ExampleMod.CONFIG.soundLogSize ){
                log.subList(0, log.size() - ExampleMod.CONFIG.soundLogSize).clear();
            }
        } finally {
            lock.unlock();
        }
    }

    public static JsonArray serialize() {
        return serialize(0);
    }

    public static JsonArray serialize(int prevIndex) {
        JsonArray arr = new JsonArray();
        try {
            lock.lock();
            for ( LogEntry e : log ) {
                if ( e.index > prevIndex) {
                    arr.add( e.serialize() );
                }
            }
        } finally {
            lock.unlock();
        }
        return arr;
    }
}
