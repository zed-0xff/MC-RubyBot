package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;
import net.fabricmc.example.handlers.ActionHandler;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import net.minecraft.client.sound.SoundInstance;
import net.minecraft.client.sound.SoundManager;

import com.google.gson.*;

@Mixin(SoundManager.class)
public class MixinSoundManager {

    private static JsonElement _serialize(SoundInstance src) {
        JsonObject obj = new JsonObject();
        obj.addProperty("id", src.getId().toString());
        obj.addProperty("pitch", src.getPitch());
        obj.addProperty("volume", src.getVolume());
//        if (src.isRelative()) {
//            obj.addProperty("relative", src.isRelative());
//        }
//        obj.addProperty("x", src.getX());
//        obj.addProperty("y", src.getY());
//        obj.addProperty("z", src.getZ());
        // a sound can also have Entity / ClientPlayerEntity (for elytra)
        return obj;
    }

    @Inject(
            method = "play(Lnet/minecraft/client/sound/SoundInstance;)V",
            at = @At("RETURN"),
            cancellable = true
    )
    private void play(SoundInstance sound, CallbackInfo ci) {
        if ( ExampleMod.CONFIG == null || sound == null ) return;
        if ( ExampleMod.CONFIG.logSounds && ActionHandler.soundLog != null ) {
            ActionHandler.soundLog.add(_serialize(sound));
        }
        if ( ExampleMod.CONFIG.filterSounds ) {
            if ( ActionHandler.shouldMuteSound(sound) ) {
                ci.cancel();
            }
        }
    }
}
