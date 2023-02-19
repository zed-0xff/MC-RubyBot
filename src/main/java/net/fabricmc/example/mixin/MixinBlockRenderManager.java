package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import net.minecraft.client.render.block.BlockRenderManager;
import net.minecraft.block.BlockState;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.BlockRenderView;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.client.render.VertexConsumer;
import net.minecraft.util.math.random.Random;

@Mixin(BlockRenderManager.class)
public class MixinBlockRenderManager {
//    @Inject(
//            method = "renderBlock(Lnet/minecraft/block/BlockState;Lnet/minecraft/util/math/BlockPos;Lnet/minecraft/world/BlockRenderView;Lnet/minecraft/client/util/math/MatrixStack;Lnet/minecraft/client/render/VertexConsumer;ZLnet/minecraft/util/math/random/Random;)V",
//            at = @At("HEAD"),
//            cancellable = true
//    )
//    private void renderBlock(
//            BlockState state,
//            BlockPos pos,
//            BlockRenderView world,
//            MatrixStack matrices,
//            VertexConsumer vertexConsumer,
//            boolean cull,
//            Random random,
//            CallbackInfo ci)
//    {
//    }
}
