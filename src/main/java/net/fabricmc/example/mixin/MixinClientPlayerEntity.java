package net.fabricmc.example.mixin;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import net.minecraft.client.network.ClientPlayerEntity;
import net.minecraft.text.Text;

@Mixin(ClientPlayerEntity.class)
public class MixinClientPlayerEntity {
    @Inject(
            method = "sendChatMessage(Ljava/lang/String;Lnet/minecraft/text/Text;)V",
            at = @At("HEAD"),
            cancellable = true
    )
    private void sendChatMessage(String string, Text preview, CallbackInfo ci) {
        if( string == "/stop" ) {
            ci.cancel();
        }
    }
}
