package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import net.minecraft.client.MinecraftClient;
import net.minecraft.client.sound.SoundInstance;
import net.minecraft.client.sound.SoundManager;

@Mixin(SoundManager.class)
public class MixinSoundManager {

    private static long prevTime = 0;

    @Inject(
            method = "play(Lnet/minecraft/client/sound/SoundInstance;)V",
            at = @At("RETURN")
    )
    private void play(SoundInstance sound, CallbackInfo ci) {
        if ( !ExampleMod.CONFIG.soundManager.enable || ExampleMod.LOGGER == null )
            return;

        String id = sound.getId().toString();
//        if ( !id.equals("minecraft:block.note_block.harp") && !id.equals("minecraft:block.note_block.pling") )
//            return;

        MinecraftClient mc = MinecraftClient.getInstance();
        if ( mc == null || mc.player == null || mc.currentScreen == null )
            return;

        if ( mc.player.squaredDistanceTo(sound.getX(), sound.getY(), sound.getZ()) > ExampleMod.CONFIG.soundManager.maxSqDistance )
            return;

        if ( sound.getSound() != null ) {
            long now = System.currentTimeMillis();
            long dt = now - prevTime;
            ExampleMod.LOGGER.info("sound: " + id + ", pitch:" + sound.getPitch() + ", dt: " + dt);
            prevTime = now;
        }
    }
}
