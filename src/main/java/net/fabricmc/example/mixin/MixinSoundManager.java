package net.fabricmc.example.mixin;

import net.fabricmc.example.handlers.ActionHandler;
import net.fabricmc.example.SoundLog;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import net.minecraft.client.sound.SoundInstance;
import net.minecraft.client.sound.SoundManager;

@Mixin(SoundManager.class)
public class MixinSoundManager {

    @Inject(
            method = "play(Lnet/minecraft/client/sound/SoundInstance;)V",
            at = @At("HEAD"),
            cancellable = true
    )
    private void play(SoundInstance sound, CallbackInfo ci) {
        SoundLog.add(sound);
        if ( ActionHandler.shouldMuteSound(sound) ) {
            ci.cancel();
        }
    }
}
