package net.fabricmc.example.mixin;

import net.fabricmc.example.HudOverlay;

import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import net.minecraft.client.MinecraftClient;
import net.minecraft.client.gui.screen.ingame.HandledScreen;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.screen.slot.Slot;
import net.minecraft.client.font.TextRenderer;
import com.mojang.blaze3d.systems.RenderSystem;

import com.mojang.blaze3d.systems.RenderSystem;

@Mixin(HandledScreen.class)
public class MixinHandledScreen {

//    @Inject(method = "drawSlot(Lnet/minecraft/client/util/math/MatrixStack;Lnet/minecraft/screen/slot/Slot;)V", at = @At("RETURN"))
//    private void drawSlot2(MatrixStack matrices, Slot slot, CallbackInfo ci) {
//        TextRenderer textRenderer = MinecraftClient.getInstance().textRenderer;
//        int color = 0xFFFFFFFF;
//
//        GL11.glDisable(GL11.GL_DEPTH_TEST);
//        ((HandledScreen)(Object)this).drawStringWithShadow( matrices, textRenderer, "1", slot.x + 1, slot.y + 1, color );
//
//        GL11.glEnable(GL11.GL_DEPTH_TEST);
//    }

    @Inject(method = "render", at = @At("RETURN"))
    private void onGameOverlayPost(MatrixStack matrixStack, int mouseX, int mouseY, float delta, CallbackInfo ci)
    {

//        RenderSystem.disableDepthTest();
//        RenderSystem.disableTexture();
//        RenderSystem.disableBlend();
        matrixStack.push();
        // zLevel - should be greater than ItemStack one, and less than Tooltip
        // 200: regular items
        // 2xx: animated (enchanted) items
        //      <-- we should draw here
        // 300: tooltips
        matrixStack.translate(0, 0, 280);
        HudOverlay.onRenderGameOverlayPost(matrixStack, null, (HandledScreen)(Object)this);
        matrixStack.pop();
//        RenderSystem.enableBlend();
//        RenderSystem.enableTexture();
//        RenderSystem.enableDepthTest();
    }
}
