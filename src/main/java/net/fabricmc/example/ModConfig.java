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
    public int minActionDelay       = 3;
    public int maxRandomActionDelay = 4;

    public static class SoundManagerConfig {
        public boolean enable = false;
        public double maxSqDistance = 4.0;
    }

    @ConfigEntry.Category("SoundManager")
    @ConfigEntry.Gui.TransitiveObject
    public SoundManagerConfig soundManager = new SoundManagerConfig();

    public static class EntityRenderDispatcherConfig {
        public boolean enable = false;
    }

    @ConfigEntry.Category("EntityRenderDispatcher")
    @ConfigEntry.Gui.TransitiveObject
    public EntityRenderDispatcherConfig entityRenderDispatcher = new EntityRenderDispatcherConfig();
}
