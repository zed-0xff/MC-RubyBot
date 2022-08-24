package net.fabricmc.example;

import java.util.Arrays;
import java.util.List;

import me.shedaniel.autoconfig.ConfigData;
import me.shedaniel.autoconfig.annotation.Config;
import me.shedaniel.autoconfig.annotation.ConfigEntry;
import me.shedaniel.autoconfig.annotation.ConfigEntry.*;
import me.shedaniel.autoconfig.annotation.ConfigEntry.Gui.*;
import me.shedaniel.cloth.clothconfig.shadowed.blue.endless.jankson.Comment;

@Config(name = ExampleMod.MOD_ID)
public class ModConfig implements ConfigData {

    public boolean debug            = false;
    public boolean experimental     = false;

    public int minActionDelay       = 3;
    public int maxRandomActionDelay = 4;

    public boolean logSounds        = true;
    public boolean filterSounds     = true;
    public int soundLogSize         = 100;

//    public static class SoundManagerConfig {
//        public boolean enable = false;
//        public double maxSqDistance = 4.0;
//    }
//
//    @ConfigEntry.Category("SoundManager")
//    @ConfigEntry.Gui.TransitiveObject
//    public SoundManagerConfig soundManager = new SoundManagerConfig();

    public static class HacksConfig {
        public boolean carrots = true;
        public boolean cobweb = true;
        public boolean cocoa = true;
        public boolean mushroom = true;
        public boolean nether_wart = true;
        public boolean potatoes = true;
        public boolean sugar_cane = true;
        public boolean wheat = true;
    }

    @ConfigEntry.Category("hacks")
    @ConfigEntry.Gui.TransitiveObject
    public HacksConfig hacks = new HacksConfig();

    public static class CobWebConfig {
        public boolean isSolidBlock = true;
        public boolean isSolidSurface = true;
        public boolean isAir        = false;
        public boolean isTranslucent = false;
        public boolean emptyRaycastShape = false;
        public boolean emptyCameraCollisionShape = false;
        public boolean emptyOutlineShape = false;
        public boolean convertToAir = false;
        public int     opacity      = 100;
    }

    @ConfigEntry.Category("cobweb")
    @ConfigEntry.Gui.TransitiveObject
    public CobWebConfig cobweb = new CobWebConfig();

    public static class EntityRenderDispatcherConfig {
        public boolean enable = false;
    }

    @ConfigEntry.Category("EntityRenderDispatcher")
    @ConfigEntry.Gui.TransitiveObject
    public EntityRenderDispatcherConfig entityRenderDispatcher = new EntityRenderDispatcherConfig();
}
