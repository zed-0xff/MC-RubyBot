package net.fabricmc.example.mixin;

import net.fabricmc.example.HudOverlay;

import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import net.minecraft.client.MinecraftClient;
import net.minecraft.client.gui.hud.InGameHud;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.client.gui.screen.ingame.HandledScreen;
import net.minecraft.text.Text;

@Mixin(InGameHud.class)
public abstract class MixinInGameHud
{
    @Shadow @Final private MinecraftClient client;

    @Inject(method = "render", at = @At("RETURN"))
    private void onGameOverlayPost(MatrixStack matrixStack, float partialTicks, CallbackInfo ci)
    {
        MinecraftClient mc = this.client;
        if ( mc.currentScreen == null || !(mc.currentScreen instanceof HandledScreen) ) {
            HudOverlay.onRenderGameOverlayPost(matrixStack, mc, (InGameHud)(Object)this);
        }
    }

    @Shadow Text title;
    public Text getTitle() {
        return this.title;
    }

    @Shadow Text subtitle;
    public Text getSubtitle() {
        return this.subtitle;
    }
}
