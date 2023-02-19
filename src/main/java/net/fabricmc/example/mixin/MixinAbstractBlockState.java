package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import net.minecraft.block.AbstractBlock.AbstractBlockState;
import net.minecraft.block.Block;
import net.minecraft.block.Blocks;
import net.minecraft.block.ShapeContext;
import net.minecraft.world.BlockView;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.shape.VoxelShape;
import net.minecraft.util.shape.VoxelShapes;
import net.minecraft.entity.Entity;
import net.minecraft.util.math.Direction;

import net.minecraft.state.property.Property;
import net.minecraft.state.property.Properties;
import net.minecraft.state.property.IntProperty;
//import java.util.Optional;

@Mixin(AbstractBlockState.class)
public class MixinAbstractBlockState {

    @Shadow
    public Block getBlock() {
        // body ignored
        return null;
    }

    @Inject( method = "getBlock()Lnet/minecraft/block/Block;", at = @At("RETURN"), cancellable = true)
    void patchedGetBlock(CallbackInfoReturnable<Block> cir) {
        if ( ExampleMod.CONFIG != null && ExampleMod.CONFIG.experimental && ExampleMod.CONFIG.cobweb.convertToAir ) {
            if (cir.getReturnValue() == Blocks.COBWEB) {
                cir.setReturnValue(Blocks.AIR);
            }
        }
    }

    // visually hides block, but not prevents raytraces/hits
    @Inject( method = "isAir()Z", at = @At("HEAD"), cancellable = true)
    private void isAir(CallbackInfoReturnable<Boolean> cir) {
        if ( ExampleMod.CONFIG == null ) return;
        if ( ExampleMod.CONFIG.hacks.tall_grass && getBlock() == Blocks.TALL_GRASS ) {
            cir.setReturnValue(true);
        } else if ( ExampleMod.CONFIG.hacks.grass && getBlock() == Blocks.GRASS ) {
            cir.setReturnValue(true);
        }
    }

    // no effect
    @Inject( method = "isSolidBlock(Lnet/minecraft/world/BlockView;Lnet/minecraft/util/math/BlockPos;)Z", at = @At("HEAD"), cancellable = true)
    void isSolidBlock(BlockView world, BlockPos pos, CallbackInfoReturnable<Boolean> cir) {
        if ( ExampleMod.CONFIG != null && ExampleMod.CONFIG.experimental ) {
            if (getBlock() == Blocks.COBWEB) {
                cir.setReturnValue(ExampleMod.CONFIG.cobweb.isSolidBlock);
            }
        }
    }

    @Inject( method = "isSolidSurface(Lnet/minecraft/world/BlockView;Lnet/minecraft/util/math/BlockPos;Lnet/minecraft/entity/Entity;Lnet/minecraft/util/math/Direction;)Z", at = @At("HEAD"), cancellable = true)
    void isSolidSurface(BlockView world, BlockPos pos, Entity entity, Direction direction, CallbackInfoReturnable<Boolean> cir) {
        if ( ExampleMod.CONFIG != null && ExampleMod.CONFIG.experimental ) {
            if (getBlock() == Blocks.COBWEB) {
                cir.setReturnValue(ExampleMod.CONFIG.cobweb.isSolidSurface);
            }
        }
    }

    @Inject( method = "getRaycastShape(Lnet/minecraft/world/BlockView;Lnet/minecraft/util/math/BlockPos;)Lnet/minecraft/util/shape/VoxelShape;", at = @At("HEAD"), cancellable = true)
    void getRaycastShape(BlockView world, BlockPos pos, CallbackInfoReturnable<VoxelShape> cir) {
        if ( ExampleMod.CONFIG != null && ExampleMod.CONFIG.experimental ) {
            if (getBlock() == Blocks.COBWEB) {
                if (ExampleMod.CONFIG.cobweb.emptyRaycastShape ) {
                    cir.setReturnValue(VoxelShapes.empty());
                }
            }
        }
    }

    @Inject( method = "getCameraCollisionShape(Lnet/minecraft/world/BlockView;Lnet/minecraft/util/math/BlockPos;Lnet/minecraft/block/ShapeContext;)Lnet/minecraft/util/shape/VoxelShape;",
    at = @At("HEAD"), cancellable = true)
    void getCameraCollisionShape(BlockView world, BlockPos pos, ShapeContext context, CallbackInfoReturnable<VoxelShape> cir) {
        if ( ExampleMod.CONFIG != null && ExampleMod.CONFIG.experimental ) {
            if (getBlock() == Blocks.COBWEB) {
                if (ExampleMod.CONFIG.cobweb.emptyCameraCollisionShape ) {
                    cir.setReturnValue(VoxelShapes.empty());
                }
            }
        }
    }

    @Inject( method = "getOutlineShape(Lnet/minecraft/world/BlockView;Lnet/minecraft/util/math/BlockPos;)Lnet/minecraft/util/shape/VoxelShape;",
    at = @At("HEAD"), cancellable = true)
    void getOutlineShape(BlockView world, BlockPos pos, CallbackInfoReturnable<VoxelShape> cir) {
        if ( ExampleMod.CONFIG != null && ExampleMod.CONFIG.experimental ) {
            Block block = getBlock();
            if (block == Blocks.COBWEB) {
                if (ExampleMod.CONFIG.cobweb.emptyOutlineShape ) {
                    cir.setReturnValue(VoxelShapes.empty());
                }
            } else if (block == Blocks.RED_MUSHROOM || block == Blocks.BROWN_MUSHROOM) {
                if (ExampleMod.CONFIG.cobweb.emptyOutlineShape ) {
                    cir.setReturnValue(VoxelShapes.fullCube());
                }
            }
        }
    }

    @Inject( method = "getOutlineShape(Lnet/minecraft/world/BlockView;Lnet/minecraft/util/math/BlockPos;Lnet/minecraft/block/ShapeContext;)Lnet/minecraft/util/shape/VoxelShape;",
    at = @At("HEAD"), cancellable = true)
    void getOutlineShape2(BlockView world, BlockPos pos, ShapeContext context, CallbackInfoReturnable<VoxelShape> cir) {
        if ( ExampleMod.CONFIG != null ) {
            Block block = getBlock();
            if ( ExampleMod.CONFIG.hacks.cobweb && block == Blocks.COBWEB) {
                cir.setReturnValue(VoxelShapes.empty());
            } else if ( ExampleMod.CONFIG.hacks.tall_grass && block == Blocks.TALL_GRASS) {
                cir.setReturnValue(VoxelShapes.empty());
            } else if ( ExampleMod.CONFIG.hacks.grass && block == Blocks.GRASS) {
                cir.setReturnValue(VoxelShapes.empty());
            } else if ( ExampleMod.CONFIG.hacks.mushroom && (block == Blocks.RED_MUSHROOM || block == Blocks.BROWN_MUSHROOM)) {
                cir.setReturnValue(VoxelShapes.fullCube());
            } else if ( ExampleMod.CONFIG.hacks.cocoa && block == Blocks.COCOA ) {
                Integer age = ((AbstractBlockState)(Object)this).get(Properties.AGE_2);
                if ( age == null ) return;
                if ( age < Properties.AGE_2_MAX ) {
                    cir.setReturnValue(VoxelShapes.empty());
                }
            } else if ( ExampleMod.CONFIG.hacks.carrots && block == Blocks.CARROTS ) {
                Integer age = ((AbstractBlockState)(Object)this).get(Properties.AGE_7);
                if ( age == null ) return;
                if ( age < Properties.AGE_7_MAX ) {
                    cir.setReturnValue(VoxelShapes.empty());
                } else {
                    cir.setReturnValue(VoxelShapes.fullCube());
                }
            } else if ( ExampleMod.CONFIG.hacks.potatoes && block == Blocks.POTATOES ) {
                Integer age = ((AbstractBlockState)(Object)this).get(Properties.AGE_7);
                if ( age == null ) return;
                if ( age < Properties.AGE_7_MAX ) {
                    cir.setReturnValue(VoxelShapes.empty());
                } else {
                    cir.setReturnValue(VoxelShapes.fullCube());
                }
            } else if ( ExampleMod.CONFIG.hacks.wheat && block == Blocks.WHEAT ) {
                Integer age = ((AbstractBlockState)(Object)this).get(Properties.AGE_7);
                if ( age == null ) return;
                if ( age < Properties.AGE_7_MAX ) {
                    cir.setReturnValue(VoxelShapes.empty());
                } else {
                    cir.setReturnValue(VoxelShapes.fullCube());
                }
            } else if ( ExampleMod.CONFIG.hacks.nether_wart && block == Blocks.NETHER_WART ) {
                cir.setReturnValue(VoxelShapes.fullCube());
            } else if ( ExampleMod.CONFIG.hacks.sugar_cane && block == Blocks.SUGAR_CANE ) {
                cir.setReturnValue(VoxelShapes.fullCube());
            } else if ( ExampleMod.CONFIG.hacks.carpet && (block == Blocks.GRAY_CARPET || block == Blocks.LIGHT_GRAY_CARPET)) {
                cir.setReturnValue(VoxelShapes.empty());
            }
        }
    }

//    @Inject( method = "getOpacity(Lnet/minecraft/world/BlockView;Lnet/minecraft/util/math/BlockPos;)I", at = @At("HEAD"), cancellable = true)
//    void getOpacity(BlockView world, BlockPos pos, CallbackInfoReturnable<Integer> cir) {
//        if ( ExampleMod.CONFIG != null && ExampleMod.CONFIG.experimental ) {
//            if (getBlock() == Blocks.COBWEB) {
//                cir.setReturnValue(ExampleMod.CONFIG.cobweb.opacity);
//            }
//        }
//    }
//
//    @Inject( method = "isTranslucent(Lnet/minecraft/world/BlockView;Lnet/minecraft/util/math/BlockPos;)Z", at = @At("HEAD"), cancellable = true)
//    void isTranslucent(BlockView world, BlockPos pos, CallbackInfoReturnable<Boolean> cir) {
//        if ( ExampleMod.CONFIG != null && ExampleMod.CONFIG.experimental ) {
//            if (getBlock() == Blocks.COBWEB) {
//                cir.setReturnValue(ExampleMod.CONFIG.cobweb.isTranslucent);
//            }
//        }
//    }

}
