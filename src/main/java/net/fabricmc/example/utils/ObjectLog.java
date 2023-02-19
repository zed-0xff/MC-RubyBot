package net.fabricmc.example.utils;

import net.fabricmc.example.ExampleMod;

import java.util.Vector;
import java.util.concurrent.locks.ReentrantLock;

import com.google.gson.*;

public class ObjectLog {

    private final ReentrantLock lock = new ReentrantLock();
    private final JsonArray log = new JsonArray();
    private int index = 0;
    private final int maxSize;

    public ObjectLog(int maxSize){
        this.maxSize = maxSize;
    }

    public void add( JsonElement obj ) {
        if ( obj == null ) return;
        add( obj.getAsJsonObject() );
    }

    public void add( JsonObject obj ) {
        if ( obj == null ) return;

        try {
            lock.lock();
            obj.addProperty("index", index++);
            obj.addProperty("tick", ExampleMod.tick);
            log.add(obj);
            while ( log.size() > maxSize ){
                log.remove(0);
            }
        } finally {
            lock.unlock();
        }
    }

    public JsonArray serialize() {
        return log;
    }

    public JsonArray serialize(int prevIndex) {
        JsonArray arr = new JsonArray();
        try {
            lock.lock();
            for ( JsonElement obj : log ) {
                if ( obj.getAsJsonObject().getAsJsonPrimitive("index").getAsInt() > prevIndex) {
                    arr.add( obj );
                }
            }
        } finally {
            lock.unlock();
        }
        return arr;
    }
}
