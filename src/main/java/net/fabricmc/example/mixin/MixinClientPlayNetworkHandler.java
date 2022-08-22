package net.fabricmc.example.mixin;

import net.fabricmc.example.handlers.ActionHandler;
import net.fabricmc.example.handlers.StatusHandler;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(net.minecraft.client.network.ClientPlayNetworkHandler.class)
public abstract class MixinClientPlayNetworkHandler {
    @Inject(method = "onGameMessage", at = @At("HEAD"), cancellable = true)
    private void onGameMessage(net.minecraft.network.packet.s2c.play.GameMessageS2CPacket packet, CallbackInfo ci)
    {
        String msg = packet.content().getString();
        StatusHandler.handleMessage(packet.overlay(), msg);
        if ( ActionHandler.shouldHideMessage(packet.overlay(), msg)) {
            ci.cancel();
        }
    }
}
