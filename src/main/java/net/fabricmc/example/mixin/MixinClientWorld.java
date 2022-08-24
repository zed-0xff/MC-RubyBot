package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import net.minecraft.client.world.ClientWorld;
import net.minecraft.util.math.BlockPos;

import net.minecraft.world.WorldView;

@Mixin(WorldView.class)
public interface MixinClientWorld {
// not really...
//    @Inject(
//        method = "isAir(Lnet/minecraft/util/math/BlockPos;)Z",
//        at = @At("HEAD"),
//        cancellable = true
//    )
//    private void isAir(BlockPos pos, CallbackInfoReturnable<Boolean> cir) {
//        if ( ExampleMod.LOGGER != null && ExampleMod.CONFIG.experimental ) {
//            ExampleMod.LOGGER.info("[d] isAir " + pos);
//        }
//    }
}
